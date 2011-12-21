require 'redmine'

# Redmine 0.8.x patches
module RedmineWikiIssueDetails
  module IssueCompatibilityPatch
    def self.included(base)
      base.class_eval do
        named_scope :visible, lambda {|*args| { :include => :project,
            :conditions => Project.allowed_to_condition(args.first || User.current, :view_issues) } }
      end
    end
  end
end

# Patches to the Redmine core.
require 'dispatcher'

Dispatcher.to_prepare :redmine_wiki_issue_details do
  require_dependency 'issue'
  Issue.send(:include, RedmineWikiIssueDetails::IssueCompatibilityPatch) unless Issue.respond_to? :visible
end

  Redmine::WikiFormatting::Macros.register do
    desc "Display an issue and it's details.  Examples:\n\n" +
      "  !{{issue_details(100)}}\n\n" +
      "  Digitized 24 hour firmware - Bug #391 Robust disintermediate customer loyalty - 25.23 hours"
    macro :issue_details do |obj, args|
      issue_id = args[0]
      issue = Issue.visible.find_by_id(issue_id)

      return '' unless issue

      if Redmine::AccessControl.permission(:view_estimates) && !User.current.allowed_to?(:view_estimates, issue.project)
        # Check if the view_estimates permission is defined and the user
        # is allowed to view the estimate
        estimates = ''
      elsif issue.estimated_hours && issue.estimated_hours > 0
        estimates = "- #{l_hours(issue.estimated_hours)}"
      else
        estimates = "- <strong>#{l(:redmine_wiki_issue_details_text_needs_estimate)}</strong>"
      end

      project_link = link_to(h(issue.project), :controller => 'projects', :action => 'show', :id => issue.project)
        
      returning '' do |response|
        response << '<span style="text-decoration: line-through;">' if issue.closed?
        response << project_link
        response << ' - '
        response << link_to_issue(issue) + ' '
        response << estimates + ' '
        response << "(#{h(issue.status)})"
        response << '</span>' if issue.closed?
      end
    end

    macro :id do |obj, args|
      issue_id = args[0]
      issue = Issue.visible.find_by_id(issue_id)

      return '' unless issue

      if Redmine::AccessControl.permission(:view_estimates) && !User.current.allowed_to?(:view_estimates, issue.project)
        # Check if the view_estimates permission is defined and the user
        # is allowed to view the estimate
        estimates = ''
      elsif issue.estimated_hours && issue.estimated_hours > 0
        estimates = "- #{l_hours(issue.estimated_hours)}"
      else
        estimates = "- <strong>#{l(:redmine_wiki_issue_details_text_needs_estimate)}</strong>"
      end

      project_link = link_to(h(issue.project), :controller => 'projects', :action => 'show', :id => issue.project)
        
      returning '' do |response|
        response << '<span style="text-decoration: line-through;">' if issue.closed?
        response << project_link
        response << ' - '
        response << link_to_issue(issue) + ' '
        response << estimates + ' '
        response << "(#{h(issue.status)})"
        response << '</span>' if issue.closed?
      end
    end
  end

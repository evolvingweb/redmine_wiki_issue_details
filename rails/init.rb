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


Redmine::Plugin.register :redmine_wiki_issue_details do
  name 'Redmine Wiki Issue Details plugin'
  author 'Eric Davis'
  url 'https://projects.littlestreamsoftware.com/projects/redmine-misc'
  author_url 'http://www.littlestreamsoftware.com'
  description 'This plugin adds a wiki macro to make it easier to list the details of issues on a wiki page.'
  version '0.1.0'
  requires_redmine :version_or_higher => '0.8.0'

  Redmine::WikiFormatting::Macros.register do
    desc "Display an issue and it's details.  Examples:\n\n" +
      "  !{{issue_details(100)}}\n\n" +
      "  Digitized 24 hour firmware - Bug #391 Robust disintermediate customer loyalty - 25.23 hours"
     block = lambda do |obj, args|
      issue_id = args[0]
      issue = Issue.visible.find_by_id(issue_id)

      return '' unless issue

      project_link = link_to(h(issue.project), :controller => 'projects', :action => 'show', :id => issue.project)

      # Collect extra information in case we need to display it.
      priority = IssuePriority.find_by_id(issue.priority_id).name

      # if IssueCategory.find_by_id(issue.category_id) then
      #   category = IssueCategory.find_by_id(issue.category_id).name
      # else
      #   category = "<strong>No Category</strong>"
      # end

      if User.find_by_id(issue.assigned_to_id) then 
        assignee = User.find_by_id(issue.assigned_to_id).name
      else 
        assingee = "<strong>Unassigned</strong>"
      end
      
      # Remove whitespace from args for better parsing.
      args.collect{|x| x.strip!}
        
      returning '' do |response|
        response << '<span style="text-decoration: line-through;">' if issue.closed?
        response << project_link
        # response << ' <' + category + '>' if args[1..-1].include? 'version'
        response << ' - '
        response << "(" + priority + ")" + ' ' if args[1..-1].include? 'priority'
        response << link_to_issue(issue) + ' '
        response << "(#{h(issue.status)})"
        response << ": " + assignee if args[1..-1].include? 'assignee'
        response << '</span>' if issue.closed?
      end
    end
    macro :issue_details, &block
    macro :id, &block
  end
end

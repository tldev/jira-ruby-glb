require 'cgi'

module JIRA
  module Resource

    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base

      has_one :reporter,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :assignee,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :project,   :nested_under => 'fields'

      has_one :issuetype, :nested_under => 'fields'

      has_one :priority,  :nested_under => 'fields'

      has_one :status,    :nested_under => 'fields'

      has_many :transitions

      has_many :components, :nested_under => 'fields'

      has_many :comments, :nested_under => ['fields','comment']

      has_many :attachments, :nested_under => 'fields',
                          :attribute_key => 'attachment'

      has_many :versions, :nested_under => 'fields'

      has_many :worklogs, :nested_under => ['fields','worklog']

      def self.all(client)
        response = client.get(
          client.options[:rest_base_path] + "/search",
          :expand => 'transitions.fields'
        )
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def self.jql(client, jql, fields = nil, page_size = 100, start_at = 0, max_results = 99999999)
        result_issues = []
        result_count = 0
        loop do
          new_issues = self.get_issues_by_jql(client, jql, fields, page_size, start_at)
          result_issues += new_issues
          result_count = new_issues.length

          break if result_count.zero?

          start_at += result_count

          break if start_at > max_results
        end

        result_issues[0...max_results]
      end

      def respond_to?(method_name)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          attrs['fields'][method_name.to_s]
        else
          super(method_name)
        end
      end

      private
      def self.get_issues_by_jql(client, jql, fields, page_size, start_at)
        url = client.options[:rest_base_path] + "/search?jql=" + CGI.escape(jql)
        url += CGI.escape("&fields=#{fields.join(",")}") if fields
        url += "&startAt=#{start_at}"
        url += "&maxResults=#{page_size}"

        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

    end

  end
end

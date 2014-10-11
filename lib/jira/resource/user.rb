module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
      delegate_to_target_class :all, :find, :collection_path, :singular_path, :find_by_group
    end

    class User < JIRA::Base
      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end

      def self.find_by_group(client, group_name)
        url = client.options[:rest_base_path] + "/group?groupname=#{group_name}&expand=users"
        response = client.get(url)
        json = parse_json(response.body)
        json['users']['items'].map do |user|
          client.User.build(user)
        end
      end
    end

  end
end

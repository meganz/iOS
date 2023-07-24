module Fastlane
  module Actions
    class CheckRepoIsInternalAction < Action
      def self.run(params)
        begin
          if `git remote get-url origin`.include?('code.developers.mega.co.nz')
            UI.message("The Git repository is hosted internally.")
            return true
          else
            UI.message("The Git repository is NOT hosted internally.")
            return false
          end
        rescue => e
          UI.message("An unexpected error occurred while check for git repo: #{e.message}")
          return false
        end
      end

      def self.description
        'Check if the Git repository is internal.'
      end

      def self.return_value
        "Boolean: true if the Git repo is internal, false otherwise"
      end

      def self.authors
        ['MEGA']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end

require 'socket'

Zeus::Server.define! do
  stage :boot do

    action do
      ROOT_PATH = File.expand_path(Dir.pwd)
      ENV_PATH  = File.expand_path('config/environment',  ROOT_PATH)
      BOOT_PATH = File.expand_path('config/boot',  ROOT_PATH)
      APP_PATH  = File.expand_path('config/application',  ROOT_PATH)

      require BOOT_PATH
      require 'rails/all'
    end

    stage :default_bundle do
      action { Bundler.require(:default) }

      stage :development_environment do
        action do
          Bundler.require(:development)
          Rails.env = ENV['RAILS_ENV'] = "development"
          require APP_PATH
          Rails.application.require_environment!
        end

        command :generate, :g do
          require 'rails/commands/generate'
        end

        command :runner, :r do
          require 'rails/commands/runner'
        end

        command :console, :c do
          require 'rails/commands/console'
          Rails::Console.start(Rails.application)
        end

        command :server, :s do
          require 'rails/commands/server'
          server = Rails::Server.new
          Dir.chdir(Rails.application.root)
          server.start
        end

        stage :prerake do
          action do
            require 'rake'
            load 'Rakefile'
          end

          command :rake do
            Rake.application.run
          end

        end
      end

      stage :test_environment do
        action do
          Bundler.require(:test)

          Rails.env = ENV['RAILS_ENV'] = 'test'
          require APP_PATH

          $rails_rake_task = 'yup' # lie to skip eager loading
          Rails.application.require_environment!
          $rails_rake_task = nil

          test = File.join(ROOT_PATH, 'test')
          $LOAD_PATH.unshift(test) unless $LOAD_PATH.include?(test)
          $LOAD_PATH.unshift(ROOT_PATH) unless $LOAD_PATH.include?(ROOT_PATH)
        end

        stage :test_helper do
          action { require 'test_helper' }

          command :testrb do
            (r = Test::Unit::AutoRunner.new(true)).process_args(ARGV) or
              abort r.options.banner + " tests..."
            exit r.run
          end
        end

      end

    end
  end
end


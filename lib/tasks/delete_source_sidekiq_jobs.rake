namespace :sidekiq do
  desc 'Delete migrated Sidekiq jobs from Redis'
  task :delete_jobs, ['dry_run', 'source_redis_url'] => :environment do |_, args|
    require 'sidekiq/api'
    require 'redis'

    # 環境変数REDIS_URLをセットすると、Sidekiq API呼び出し時にそのURLを利用してコネクションを張る
    ENV['REDIS_URL'] = args.source_redis_url

    # 移行元のスケジュールされたjobを取得する
    # Ref: https://github.com/sidekiq/sidekiq/wiki/API#scheduled
    ss = Sidekiq::ScheduledSet.new

    # 中身の確認(job名と予約日時)
    ss.each do |job|
      puts "[check] Delete job from source: #{job.klass}, #{job.at}"
    end

    # 引数でdry_runが指定されている場合は、移行元のjobを表示して終了
    if args.dry_run == 'false'
      # 移行元のスケジュールされたjobを削除する
      ss.each do |job|
        puts "[actual execution] Delete job from source: #{job.klass}, #{job.at}"
        job.delete
      end
    end
  end
end

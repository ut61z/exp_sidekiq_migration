namespace :sidekiq do
  desc 'Migrate Sidekiq jobs from one Redis to another'
  # 引数で 移行元のRedisのURLと移行先のRedisのURLを受け取る
  task :migrate_jobs, ['dry_run', 'source_redis_url', 'target_redis_url' ] => :environment do |_, args|
    require 'sidekiq/api'
    require 'redis'

    # Ref: https://github.com/sidekiq/sidekiq/blob/79d254d9045bb5805beed6aaffec1886ef89f71b/lib/sidekiq/api.rb#L609-L611
    # Ref: https://github.com/sidekiq/sidekiq/blob/79d254d9045bb5805beed6aaffec1886ef89f71b/lib/sidekiq/api.rb#L776
    SCHEDULED_SET = 'schedule'

    # 環境変数REDIS_URLをセットすると、Sidekiq API呼び出し時にそのURLを利用してコネクションを張る
    ENV['REDIS_URL'] = args.source_redis_url

    # Sidekiqのコネクションは動的には変更できないため、別のredis clientを使う (移行先のRedisにレコードを追加するために使う)
    target_redis = Redis.new(url: args.target_redis_url)

    # 移行元のスケジュールされたjobを取得する
    # Ref: https://github.com/sidekiq/sidekiq/wiki/API#scheduled
    ss = Sidekiq::ScheduledSet.new

    # 中身の確認(job名と予約日時)
    ss.each do |job|
      puts "[check] Migrate job from source to target: #{job.klass}, #{job.at}"
    end

    # 引数でdry_runが指定されている場合は、移行元のjobを表示して終了
    if args.dry_run == 'false'
      # 移行元のスケジュールされたjobを移行先のRedisに追加する
      ss.each do |job|
        puts "[actual execution] Migrate job from source to target: #{job.klass}, #{job.at}"
        # Ref: https://github.com/sidekiq/sidekiq/blob/79d254d9045bb5805beed6aaffec1886ef89f71b/lib/sidekiq/api.rb#L667
        target_redis.zadd(SCHEDULED_SET, job.at.to_f.to_s, Sidekiq.dump_json(job.item))
      end
    end
  end
end

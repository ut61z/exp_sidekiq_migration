# SidekiqのScheduled Jobのマイグレーション シミュレーション
## What's This?
SidekiqのジョブをキューイングするRedisを既存のものから別のものへ変更したいとき、Scheduled Jobsをマイグレーションするための簡単なRake Task
また、そのRake Taskを実際に試行するための環境をDockerで構築可能としたもの

## 操作方法

### Dockerを立ち上げる

```sh
docker compose up --build -d
```

docker-composeの中身は以下になります
- Redis(移行元を想定したRedis)
- Redis(移行先を想定したRedis)
- Sidekiq Worker(移行元Redisと接続されている)
- Sidekiq Worker(移行先Redisと接続されている)
- Ops用のインスタンス(`Rails c` ができる環境)

### Opsインスタンス上でScheduled Jobをエンキューする

ops用のインスタンスの中に入ります
```sh
docker exec -it exp_sidekiq_migration-ops-1 bash
```

```sh
bundle exec rails c
```

```ruby
irb(main):001> ENV["REDIS_URL"] = "redis://old_redis:6379/0"
=> "redis://old_redis:6379/0"

irb(main):002> HardJob.perform_at(Time.now+30*60, 'test')
2024-05-02T10:19:26.498Z pid=13 tid=2h9 INFO: Sidekiq 7.2.2 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://old_redis:6379/0"}
=> "6bd1be18d212a47555e3902f"

irb(main):003> require 'sidekiq/api'
=> true

irb(main):004> Sidekiq::ScheduledSet.new
=> #<Sidekiq::ScheduledSet:0x0000ffff75df8d68 @_size=1, @name="schedule">
```


### マイグレーションのRake Taskを実行する
**dry run**
```sh
bundle exec rake sidekiq:migrate_jobs["true","redis://old_redis:6379/0","redis://new_redis:6379/0"]
```

example
```sh
# bundle exec rake sidekiq:migrate_jobs["true","redis://old_redis:6379/0","redis://new_redis:6379/0"]
2024-05-02T10:21:55.593Z pid=23 tid=337 INFO: Sidekiq 7.2.2 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://old_redis:6379/0"}
[check] Migrate job from source to target: HardJob, 2024-05-02 10:49:26 UTC # Log from rake task. it'll show each scheduled job.
```

**execute**
```sh
bundle exec rake sidekiq:migrate_jobs["false","redis://old_redis:6379/0","redis://new_redis:6379/0"]
```

example
```sh
# bundle exec rake sidekiq:migrate_jobs["false","redis://old_redis:6379/0","redis://new_redis:6379/0"]
2024-05-02T10:24:12.752Z pid=28 tid=33c INFO: Sidekiq 7.2.2 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://old_redis:6379/0"}
[check] Migrate job from source to target: HardJob, 2024-05-02 10:49:26 UTC
[actual execution] Migrate job from source to target: HardJob, 2024-05-02 10:49:26 UTC
```

### 移行先のRedisにScheduled Jobが移行されているか確認する


```sh
bundle exec rails c
```

```ruby
irb(main):001> ENV["REDIS_URL"] = "redis://new_redis:6379/0"
=> "redis://new_redis:6379/0"

irb(main):002> require 'sidekiq/api'
=> true

irb(main):003> Sidekiq::ScheduledSet.new
=> #<Sidekiq::ScheduledSet:0x0000ffff75df8d68 @_size=1, @name="schedule"> ## sizeが想定したsizeかどうか確認
```

### 移行元のRedisからScheduled Jobを削除する

Ops用のインスタンスにて以下の操作を行う

```sh
bundle exec rails c
```

**dry run**
```sh
bundle exec rake sidekiq:delete_jobs["true","redis://old_redis:6379/0"]
```

example
```sh
bundle exec rake sidekiq:delete_jobs["true","redis://old_redis:6379/0"]
2024-05-06T23:37:20.876Z pid=35 tid=32v INFO: Sidekiq 7.2.2 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://old_redis:6379/0"}
[check] Delete job from source: HardJob, 2024-05-06 23:29:46 UTC
```

**execute**
```sh
bundle exec rake sidekiq:delete_jobs["false","redis://old_redis:6379/0"]
```

example
```sh
bundle exec rake sidekiq:delete_jobs["false","redis://old_redis:6379/0"]
2024-05-06T23:37:20.876Z pid=35 tid=32v INFO: Sidekiq 7.2.2 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://old_redis:6379/0"}
[check] Delete job from source: HardJob, 2024-05-06 23:29:46 UTC
[actual execution] Delete job from source: HardJob, 2024-05-06 23:29:46 UTC
```

以上

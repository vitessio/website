---
author: 'Manan Gupta'
date: 2021-12-17
slug: '2021-12-17-rails-that-scales'
tags: ['Vitess','MySQL','CNCF', 'Rails', 'scaling','web','framework','SQL']
title: 'Rails that scales - Powered by Vitess'
description: "Announcing compatibility of Vitess with Rails" 
---

## Past - Frameworks without scale

Over the past couple of decades, there has been a steady rise in the complexity of the development stacks that the developers across the globe have been using. 
The web has advanced from being just HTML files, to also include CSS and JavaScript with their own multitudes of frameworks like Redwood, Next.js, and Angular, among many others. The number of library dependencies that each project has has also shot up, leading to package managers like npm gaining popularity.   
All of these complexities in creating modern state-of-the-art webpages have led to the popularity of web frameworks like [Django](https://www.djangoproject.com/) and [Ruby on Rails](https://rubyonrails.org/) which take away a lot of the hassle and accelerate the development cycle. They equip developers with a much more fun environment to work in, while guaranteeing the security and speed of the end product.

Just like the stack, the amount of data that modern websites are generating and operating on has sky-rocketed, reaching never-seen-before numbers. 
For example, take a look at [GitHub’s experience scaling their growing data](https://github.blog/2021-09-27-partitioning-githubs-relational-databases-scale/) throughout the years. [Slack has a similar story](https://slack.engineering/scaling-datastores-at-slack-with-vitess/) where they turn to horizontal scaling to address the massive growth of their data. A common theme in both of these stories is the way GitHub and Slack solved their scaling issues: Horizontal sharding with Vitess. 

Having a single powerful machine has reached its physical limits and the only way forward is horizontal sharding, which is what Vitess excels at. Having state-of-the-art features like [VReplication](https://vitess.io/docs/reference/vreplication/vreplication/), [online-ddl](https://vitess.io/docs/user-guides/schema-changes/ddl-strategies/) and [Vtorc](https://vitess.io/docs/user-guides/configuration-basic/vtorc/) (experimental), Vitess is becoming the de-facto solution for all the scaling needs for data storage. If you want to know more about the history of databases, [take a look at the talk given by Dr. Andy Pavlo at the Hydra conference](https://www.youtube.com/watch?v=LwkS82zs65g). For a great [comparison between Vitess and other cloud databases, check out this article](https://planetscale.com/blog/planetscale-vs-aws-rds).

The next logical question that follows is, what if we want both, the ease of development that the web frameworks provide and the infinite scalability that distributed databases have to offer? Is it too much to ask? TL;DR With Vitess, it isn’t.


## Present - Rails, meets Vitess

Recognizing the desire of developers to use Vitess as the backing store while working with web frameworks like Django and Ruby on Rails, we embarked on a journey to make them as compatible as we possibly could. With this idea in mind, the [Vitess framework testing](https://github.com/planetscale/vitess-framework-testing) repository was born.  
It runs the major workflows from the popular frameworks and gives us confidence that Vitess does indeed work with the popular frameworks!

### Rails

Ruby on Rails follows the MVC architecture which means that Vitess’s compatibility would be concerned with the Model layer of Rails. Ruby on Rails has an [extraordinary guide](https://guides.rubyonrails.org), which documents all the permitted operations and has example code for all of them. For testing compatibility, it is sufficient that we run these examples with a sharded database and ensure the optimal user experience. Let’s dive in.

#### The setup phase

The first and foremost thing you need to do is start a sharded and an unsharded keyspace in Vitess. We’ll talk more about why the unsharded keyspace is required in a bit. If you just want to test out Vitess without running all of its components like the Vtgate and vttablets, the easiest way to do that would be via the Vttestserver docker image. To get started, run through the [Vttestserver Docker Image documentation](https://vitess.io/docs/get-started/vttestserver-docker-image/). Do not forget to enable the new Vitess planner Gen4 which adds a whole lot of query support crucial for the compatibility with Rails. To start the Vttestserver image in the desired configuration, all you need to do is run:
```bash
docker run --name=vttestserver -p 33577:33577 -e PLANNER_VERSION=gen4fallback -e PORT=33574 -e KEYSPACES=test,unsharded -e NUM_SHARDS=2,1 -e MYSQL_MAX_CONNECTIONS=70000 -e MYSQL_BIND_HOST=0.0.0.0 --health-cmd="mysqladmin ping -h127.0.0.1 -P33577" --health-interval=5s --health-timeout=2s --health-retries=5 vitess/vttestserver:mysql57
```

Next, we follow along with the [Rails guide](https://guides.rubyonrails.org/getting_started.html) to setup Rails and change the default database settings for the application. Rails, by default, starts with SQLite as the backend. To use Vitess instead, change the `database.yml` file in the config folder to this:
```yaml
development:
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("VT_HOST") %>
  database: <%= ENV.fetch("VT_DATABASE") %>
  username: <%= ENV.fetch("VT_USERNAME") %>
  password: <%= ENV.fetch("VT_PASSWORD") %>
  port: <%= ENV.fetch("VT_PORT") %>
  init_command: "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''))"
```

Checkout the configuration we are using for the [vitess-framework-testing](https://github.com/planetscale/vitess-framework-testing/blob/main/frameworks/ruby/rails6/src/config/database.yml). If you look closely, you will notice that we are using the mysql2 adapter, which might not be available by default. So add `gem 'mysql2'` to the Gemfile and run `bundle install`.

Before moving on, we need to handle just one more thing. Rails uses some tables internally for its proper functioning. When there is a single MySQL instance in the backend, that is the place that we store these tables, but when we migrate to the sharded setup, we have more than 1 instance and we need to define rules for storing all these tables. Fortunately, Vitess has a simple solution: [Vschema](https://vitess.io/docs/user-guides/vschema-guide/).   
For the purpose of this demonstration, we can just [connect to our Vitess instance](https://vitess.io/docs/get-started/vttestserver-docker-image/#example) and run the following Vschema DDL commands to tell Vitess how to store the rails internal tables.
```mysql
# Tables that rails uses internally
ALTER VSCHEMA ON test.schema_migrations ADD VINDEX \`binary\`(version) USING \`binary\`
ALTER VSCHEMA ON test.ar_internal_metadata ADD VINDEX \`xxhash\`(\`key\`) USING \`xxhash\`
ALTER VSCHEMA ON test.active_storage_attachments ADD VINDEX \`null\`(id) USING \`null\`
ALTER VSCHEMA ON test.active_storage_blobs ADD VINDEX \`null\`(id) USING \`null\`
```

And that’s all you need to get up and running with Vitess and Rails. Now you can run `rails db:migrate` without any issues.

#### The guides

As I mentioned before, the Rails guides are very comprehensive, so in our Vitess framework testing, we chose to run all of their code examples along with the Vschema commands that are required to run them. 

Just to get you warmed up, we’ll go over the article creation example in the [Getting Started guide of Rails](https://guides.rubyonrails.org/getting_started.html).

Once you have Rails and Vitess set up, you can run the Rails command `rails generate model Article title:string body:text` to create the article model. We still need to tell Vitess how to route queries for this table before we can run the migration. We do so by adding a vschema entry for this table like we did for the internal tables of Rails. Here is the Vschema DDL command that we can run: 
```mysql
ALTER VSCHEMA ON test.articles ADD VINDEX `binary`(id) USING `binary`
```

Now, run `rails db:migrate`. This command should succeed if you have added the Vschema correctly. 

#### Auto-Increment Handling

One question that we had left unanswered during the setup phase of Rails was the use of the unsharded database that we created. Well here it is!  
Handling auto increment columns in a sharded environment presents a peculiar problem. The column values have to be unique across all the different shards. Vitess handles this problem very elegantly with the use of [Sequences](https://vitess.io/docs/reference/features/vitess-sequences/), which requires an unsharded database to store the internal table. For the purpose of this demonstration, for getting the ID column in the articles table to work correctly, we need to run the following commands: 

```mysql
mysql> CREATE TABLE unsharded.`articles_seq`(id bigint, next_id bigint, cache bigint, primary key(id)) COMMENT 'vitess_sequence';
Query OK, 0 rows affected (0.01 sec)

mysql> INSERT INTO unsharded.`articles_seq`(id, next_id, cache) VALUES (0, 1, 3);
Query OK, 1 row affected (0.01 sec)

mysql> ALTER VSCHEMA ADD SEQUENCE unsharded.`articles_seq`;
Query OK, 0 rows affected (0.01 sec)

mysql> ALTER VSCHEMA ON test.`articles` ADD AUTO_INCREMENT id USING unsharded.`articles_seq`;
Query OK, 0 rows affected (0.00 sec)

```

Now, we can follow along with the rest of the getting started guide. You can go into the Rails console and run the commands for creating an article, filtering them, viewing them and updating them. They all work just as we’d like them to.

You can look at the examples from the Rails guides and the Vschema that we used to get the optimal performance for them in the [Vitess framework testing repository](https://github.com/planetscale/vitess-framework-testing/tree/main/frameworks/ruby/rails6/rails-guide). 

We cover all the examples from the five guides: [Active Records Migration](https://guides.rubyonrails.org/active_record_migrations.html), [Active Records Validations](https://guides.rubyonrails.org/active_record_validations.html), [Active Records Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html), [Active Records Associations](https://guides.rubyonrails.org/association_basics.html) and [Active Records Query Interface](https://guides.rubyonrails.org/active_record_querying.html).

## Speedbumps along the way

While trying to make Vitess compatible with Rails, we frequently encountered speedbumps that we had to fix. Some of them are listed here -

1. https://github.com/vitessio/vitess/issues/7396
2. https://github.com/vitessio/vitess/issues/7456
3. https://github.com/vitessio/vitess/issues/7636
4. https://github.com/vitessio/vitess/issues/7739
5. https://github.com/vitessio/vitess/issues/7707
6. https://github.com/vitessio/vitess/issues/7748
7. https://github.com/vitessio/vitess/issues/7791
8. https://github.com/vitessio/vitess/issues/8510
9. https://github.com/vitessio/vitess/issues/8552
10. https://github.com/vitessio/vitess/issues/8575
11. https://github.com/vitessio/vitess/issues/8580
12. https://github.com/vitessio/vitess/issues/8581
13. https://github.com/vitessio/vitess/issues/8813
14. https://github.com/vitessio/vitess/issues/9221

## Future - Infinitely scalable Vitess

Having a robust database which is infinitely scalable and an easy-to-use web framework are a must have when you start building a website. With Vitess becoming compatible with the Ruby on Rails framework, this is now possible. A big part of which is thanks to the new Vitess [Gen4 planner](https://vitess.io/blog/2021-11-02-why-write-new-planner/), which allows us to support a lot more queries than we used to. You can now build your website on the Rails framework while letting Vitess handle all the scalability for you. Welcome to the future!


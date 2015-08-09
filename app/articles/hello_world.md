title: Hello World!
date:  2015-10-12
description: The first post. I give a quick overview of how the blog was implemented, the resources I used, and the process of deploying it.

This is the first post of my first blog. It makes sense then that the post be about the blog.

The inspiration to write a blog came while reading the thin but dense [Sinatra Up And Running](http://shop.oreilly.com/product/0636920019664.do) during a flight.  The final project is a blog backed by [Sinatra](https://github.com/sinatra/sinatra) which uses git hooks to automate deployment. This was right in line with the kind of blog I wanted to write:

1. No frills simple blog a la [Jekyll](https://jekyllrb.com/)
2. A blog that supports markdown with pretty syntax highlighting
3. Having a system that I could use to deploy the blog similar to a `git push heroku master`

We'll address each of these points one by one.

#### Keep it simple, stupid

One of the core ideas from the blog project in the Sinatra book is that the articles are written to YAML files in the articles directory. Then they are dynamically loaded from there. The relevant code is in `Blog/application_controller.rb`

``` ruby
  def load_articles
    articles = []

    Dir.glob "#{Rails.root}/app/articles/*.md" do |file|
      meta, content = File.read(file).split("\n\n",2)

      article = OpenStruct.new YAML.load(meta)

      article.date = Time.parse article.date.to_s
      article.content = content

      articles << article
    end

    articles.sort_by!{|article| article.date}
    @articles = articles.reverse!
  end
```

This strikes me as a good idea for two reasons first it seems natural that the articles are treated as part of the source code of the blog. Secondly being source code means they are checked into source control this gives me all the nice benefits of source control like pretty diffs and revision history.

`OpenStruct` turns out to be useful here, because we can quickly use it to represent a simple article object instead of using something like an article class, which seems like overkill in this case since an article has no methods only attributes. We could also use a hash here, but `OpenStruct` provides a simpler implementation and the performance hit is negligible here.

Since the articles are loaded from a directory we don't need `ActiveRecord`, and since no mailing features are needed we also don't need `ActiveMailer`. And so we removed these dependencies as shown [here](http://villesiltanen.com/blog/2014/11/13/removing-action-mailer-from-a-rails-app/).

#### Down for Markdown

Rendering the markdown in the articles was easily done thanks to [redcarpet](https://github.com/vmg/redcarpet). The syntax highlight was done equally as easy using the [rouge](https://github.com/jneen/rouge) gem. Both of these were implemented in the `Blog/app/helpers/application_helper.rb`

``` ruby
class HTML < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  def markdown(text)
    extensions = {
      no_intra_emphasis:   true,
      tables:              true,
      fenced_code_blocks:  true,
      space_after_headers: true,
      superscript:         true,
      footnotes:           true,
      strikethrough:       true,
      disabled_indented_code_blocks: true
    }

    options = {
      filter_html: true,
      prettify:    true
    }

    renderer = HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end
```

We just need to call the `markdown` helper in the views. The theme for syntax highlighting is set in the `rouge.css.erb` file, the default themes that come with rouge can be found in `rouge/lib/rouge/themes/`.

#### Pop a Cap

Once the blog was done, styled, and ready to face the world I needed a way to automate the deployment. At first I was gonna write my own system based on [git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), however I decided to use [Capistrano](http://capistranorb.com/) instead, purely because I wanted to learn capistrano. There are plans however to tackle git hooks in the future.

The first step was to create a Ubuntu droplet in digital ocean following this [tutorial](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04). Once that was setup I installed rvm and rails as well as nodejs to provide the javascript runtime. Once that was set up I followed this [tutorial](https://www.digitalocean.com/community/tutorials/deploying-a-rails-app-on-ubuntu-14-04-with-capistrano-nginx-and-puma) to automate deployment using Capistrano, Puma, and Nginx. Carefully removing the parts that dealt with deploying the database.

During the tutorial a bundler error that came up was `an error occurred while installing json 1.8 2 and bundler cannot continue`. This was fixed by doing a `sudo apt-get install libgmp3-dev` on the host machine. The other issue was in setting the `SECRET_KEY_BASE` in the `secrets.yaml` file. I was having issues getting the environment variable to be read since Capistrano starts a non interactive non login shell, and environment variables are only read from the `.bashrc` during interactive login shells.

As a quick workaround I've created a `secrets.yml` file with the hardcoded secret in the host machine and then set that as a linked file to the `secrets.yml` in the development machine, while I figure out a more elegant way to deal with environment variables.

Finally after deploying to DigitalOcean I bought a domain and set it to point at my droplet's IP address following this [tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean).

And this is how my blog came to be.

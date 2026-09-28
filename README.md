# Drupal AI Workshop

A hands-on workshop for the [Drupal AI](https://www.drupal.org/project/ai) modules,
built on [Drupal CMS](https://new.drupal.org/drupal-cms) and based on the official Drupal
AI demo. You install a small sample website for the fictional Northmoor University, then
add AI features to it step by step.

Each workshop step lives in its own Git branch. The default branch, `01_setup`, is the
first step. Every later branch builds on the one before it and adds one guide to the
[docs/](docs/) folder.

Read all step guides online at **https://1xinternet.github.io/drupal_ai_workshop/**. The
links in the guides open your local workshop site, https://drupal-ai-workshop.ddev.site.

## Requirements

- [DDEV](https://ddev.com/get-started/) 1.24 or newer, with Docker
- Git
- About 4 GB of free disk space

No API key is needed: the site connects to a free trial of [amazee.ai](https://www.amazee.ai/).
You can use your own OpenAI or Anthropic key instead (see [Use your own AI provider](#use-your-own-ai-provider)).

## Get started

Run these commands before the workshop. They download everything the site needs.

```bash
git clone https://github.com/1xINTERNET/drupal_ai_workshop.git
cd drupal_ai_workshop
ddev start
ddev composer install
```

Then continue with the step guides in the [docs/](docs/) folder, starting with
[docs/01_setup.md](docs/01_setup.md).

## Useful commands

| Command | What it does |
|---|---|
| `ddev launch` | Open the site in your browser. |
| `ddev drush user:login` | Get a one-time login link. You can also log in with `admin` / `admin`. |
| `ddev drush cache:rebuild` | Clear all caches. |
| `ddev logs` | Show the web server logs. |
| `ddev drush watchdog:show` | Show recent Drupal log messages. |
| `ddev describe` | Show the URLs and services of the project. |
| `ddev stop` | Stop the project. `ddev start` brings it back. |

## Catch up or jump to a step

Each branch contains a database dump of the site as it looks at the end of that step.
If you fall behind, or want to start at a later step, check out the branch and run
`ddev catch-up`:

```bash
git checkout 01_setup
ddev catch-up
```

`ddev catch-up` replaces your database with the dump of the checked-out branch and
connects the site to the AI provider again. Changes you made to your site are lost.

## Start over

To run the whole workshop again from the beginning, go back to the first step and empty
the site:

```bash
git checkout 01_setup
ddev start
ddev composer install
ddev drush sql:drop -y
ddev exec -s postgres psql -U vectordb -d default -c "DROP TABLE IF EXISTS content_database_index"
ddev exec 'rm -rf web/sites/default/files/* .easy_encryption && mkdir web/sites/default/files/sync'
```

These commands:

1. check out the first step and install its packages;
2. delete all tables of the Drupal database;
3. delete the vector index of step 3 in PostgreSQL;
4. delete the uploaded files and the local encryption key, and recreate the empty
   configuration sync directory (`files/sync`) that DDEV sets up.

The site is now empty. Continue with [docs/01_setup.md](docs/01_setup.md), starting at
*Install the site*.

## Use your own AI provider

To use OpenAI or Anthropic instead of the amazee.ai trial, create the file `.ddev/.env`
with your key, then restart DDEV:

```bash
OPENAI_API_KEY=YOUR_OPENAI_API_KEY
# or
ANTHROPIC_API_KEY=YOUR_ANTHROPIC_API_KEY
```

```bash
ddev restart
ddev drush recipe ../recipes/workshop_ai_provider
```

If your key is set before you install the AI base in step 1, OpenAI or Anthropic becomes
the default provider. If you add it later, choose the provider and models yourself at
[/admin/config/ai/settings](https://drupal-ai-workshop.ddev.site/admin/config/ai/settings).

`.ddev/.env` is ignored by Git. Never commit API keys.

## About the content

Northmoor University does not exist. All people, programs and facilities on the sample
site are invented, and the images are AI-generated. When you use AI features, the
content of your site and your prompts are sent to the AI provider you connected.

## License

GPL-2.0-or-later, like Drupal. See [LICENSE.txt](LICENSE.txt).

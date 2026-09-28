# Drupal AI Workshop: notes for agents and maintainers

This repository is a hands-on workshop for the Drupal AI modules, built on
Drupal CMS and based on the official Drupal AI demo. Participants clone it, run DDEV, and
follow step guides.

Everything here must work with **public drupal.org packages only**, with no GitLab token.
The demo itself is not available to participants or to agents working on this
repository. Do not refer to it in guides, recipes or configuration.

## Status

| Branch | State | Guide |
|---|---|---|
| `01_setup` | Done | `docs/01_setup.md` |
| `02_automators_ckeditor` | Done | `docs/02_automators_ckeditor.md` |
| `03_ai_search` | Done | `docs/03_ai_search.md` |
| `04_ai_content_review` | Done | `docs/04_ai_content_review.md` |

The repository is published at https://github.com/1xINTERNET/drupal_ai_workshop
(public). The default branch is `01_setup`. Push every step branch after a change.

## Conventions

- **One branch per step.** Branch names are `NN_short_name`. The default branch is
  `01_setup`. Each step branches off the previous step.
- **Each branch adds exactly one guide**, `docs/NN_short_name.md`, plus its screenshots in
  `docs/images/NN_short_name/`, and a regenerated `dumps/db.sql.gz`.
- **README.md covers getting started only**: requirements, clone, DDEV commands,
  `ddev catch-up`, own API keys. It links to the `docs/` folder. It contains no step
  content and does not change per branch.
- **Guides:** explain each feature, and say which module provides it and whether that
  module is part of the AI project or a separate contributed project. Link UI paths to
  the local site, for example
  `[/admin/config/ai/settings](https://drupal-ai-workshop.ddev.site/admin/config/ai/settings)`.
  The AI Explorer (`/admin/config/ai/explorers`) is the tool for testing features, and
  guides come back to it.
- **No time budgets** in the README or the guides: no durations per step, no agenda, no
  note on whether a step fits the workshop. Planning the time is the presenter's job.
- **Screenshots:** take them with agent-browser at a 1440×900 viewport, from the real
  site, and check each one before using it. Use PNG for admin UI and JPG for pages
  with photos.
- **Content is fixed.** The 20 pages in `recipes/northmoor_university/content/` are
  static default content YAML. Do not add a content generation script.
- **Two pages contain deliberate errors.** *Visit campus* (`/visit`) and *Tuition and
  financial aid* (`/tuition-and-aid`) break the Grammar & Conventions house style on
  purpose (title-case headings, British spelling, dash ranges, "click here", exclamation
  marks, very long sentences). Step 04 (AI Content Review) reviews them. Do not fix them.
- **Commits:** end commit messages with the co-author line the session provides.

## Repository layout

```
README.md                          Getting started (all branches)
docs/NN_*.md, docs/images/NN_*/    Step guides and screenshots
.ddev/config.yaml                  Project drupal-ai-workshop, PHP 8.4, MySQL 8, DDEV-managed settings
.ddev/docker-compose.postgres.yaml pgvector service: the vector database of step 03 (AI Search)
.ddev/commands/host/catch-up       composer install, imports the dump, copies images, reconnects the AI provider, re-indexes content_vector
composer.json / composer.lock      Public packages only; config.platform.php = 8.4.0
recipes/northmoor_university/      Site recipe: Drupal CMS basics + Olivero + 20 pages, images, menus
recipes/workshop_ai_base/          Drupal CMS AI stack without image alt text, plus API Explorer and AI Logging
recipes/workshop_ai_provider/      Easy Encryption + amazee.ai trial; OpenAI/Anthropic from env vars
recipes/workshop_ai_guardrails/    Guardrail set "Workshop security" (prompt injection in, malicious code out)
recipes/workshop_ai_content_review/ Step 04: the Content Review agent and a rule with only the Grammar & Conventions criterion
dumps/db.sql.gz                    Database at the end of the branch's guide
mkdocs.yml, scripts/build-site.sh   Website with all step guides (see below)
```

Contrib recipes are installed by Composer into `recipes/` too, and are ignored by Git
through a whitelist in `.gitignore`. New workshop recipes must be named `workshop_ai_*`
or be added to that whitelist.

**Composer packages.** Steps 01 and 02 are finished; their packages are all required on
`01_setup`. From step 03 on, a step adds its packages **on its own branch**. The guide
of that step starts with `ddev composer install` and `ddev drush cache:rebuild`, and
`ddev catch-up` always runs `ddev composer install`. Do not go back and change earlier
branches for a later step.

## Guides website

All step guides are published at https://1xinternet.github.io/drupal_ai_workshop/
(GitHub Pages, served from the `gh-pages` branch, MkDocs Material). The site is built
from the **last step branch**, currently `04_ai_content_review`, because only that
branch contains every guide. After a guide changes and the branches are pushed, rebuild
and deploy it from any branch:

```bash
scripts/build-site.sh            # build into .site-build/site and check links (--strict)
scripts/build-site.sh --deploy   # build and push to gh-pages
```

The script exports `docs/` and `README.md` from that branch with `git archive`, turns
the README into the start page, and points links that leave `docs/` (recipes, license)
to GitHub. It runs MkDocs in Docker (`squidfunk/mkdocs-material:9.7`). When a new step
branch is added, change the default branch in the script and add the guide to `nav` in
`mkdocs.yml`. Never commit to `gh-pages` by hand.

## Working on the site

```bash
ddev start
ddev composer install
ddev drush site:install ../recipes/northmoor_university --site-name="Northmoor University" --account-name=admin --account-pass=admin -y
ddev drush recipe ../recipes/workshop_ai_base
```

Then follow the guides. Drush runs from `web/`, so recipe paths start with `../recipes/`.
To reset to the end of the current branch, run `ddev catch-up`.

Composer on the host: the host PHP lacks some extensions, so update the lock with
`composer update --no-install --ignore-platform-req='ext-*'`, then run
`ddev composer install`.

## Regenerating a branch dump

A dump must match the state after following the README and all guides up to and
including the branch. It must contain **no API keys, encryption keys or amazee.ai
trial details**, because every participant provisions their own on `ddev catch-up`.

1. Build the state. Either start from a fresh install and follow the guides, or run
   `ddev catch-up` on the previous branch and follow only the current guide.
2. Remove secrets and traces:

   ```bash
   ddev drush php:eval '
   $keys = \Drupal::entityTypeManager()->getStorage("key");
   foreach ($keys->loadMultiple() as $key) {
     $id = $key->id();
     if (in_array($id, ["amazeeio_ai", "amazeeio_ai_database", "openai_api_key", "anthropic_api_key"], TRUE) || str_starts_with($id, "easy_encrypted__")) { $key->delete(); }
   }
   if ($vdb = $keys->load("ai_vdb_provider_postgres")) { $vdb->setPlugin("key_provider", "env"); $vdb->set("key_provider_settings", ["env_variable" => "VECTOR_DB_PASSWORD", "base64_encoded" => FALSE, "strip_line_breaks" => TRUE]); $vdb->save(); }
   \Drupal::configFactory()->getEditable("easy_encryption.keys")->delete();
   \Drupal::configFactory()->getEditable("ai_provider_amazeeio.settings")->set("host", "")->set("postgres_host", "")->set("postgres_default_database", "")->set("postgres_username", "")->save();
   \Drupal::state()->delete("ai_provider_amazeeio.trial_account");
   $logs = \Drupal::entityTypeManager()->getStorage("ai_log"); $logs->delete($logs->loadMultiple());
   foreach (["watchdog", "sessions", "key_value_expire", "flood", "autosave_form_entity_form"] as $t) { \Drupal::database()->truncate($t)->execute(); }
   \Drupal::database()->delete("key_value")->condition("collection", "config.checkpoint%", "LIKE")->execute();
   \Drupal::keyValue("state")->delete("config.checkpoints");'
   ```

3. Export:

   ```bash
   ddev drush sql:dump --structure-tables-list='cache,cache_*,cachetags,watchdog,sessions,key_value_expire,flood,ai_log*,autosave_form_entity_form' --gzip --result-file=/var/www/html/dumps/db.sql
   ```

4. Check that this prints nothing:

   ```bash
   zcat dumps/db.sql.gz | grep -oE "sk-[A-Za-z0-9_-]{16,}|user_[0-9a-f]{8}|db_[0-9a-f]{8}|llm\.[a-z0-9.-]+amazee\.ai|vectordb[0-9]*\.[a-z0-9.-]+|easy_encrypted__[0-9a-f_]+"
   ```

   The Postgres vector DB key is switched to the env provider (`VECTOR_DB_PASSWORD`,
   set by DDEV) because its encrypted value would not survive the deleted key pair. The
   value is the local DDEV default `vectordb`, not a secret.
5. Test: `rm -rf .easy_encryption && ddev catch-up`, then send a chat request. The cleanup
   deleted the local site's keys, so this also restores your working site.

## Fixing an earlier branch

Commit the fix on the earliest affected branch, then merge it forward
(`git checkout 02_… && git merge 01_setup`), and regenerate the dump of every later
branch.

## Things that went wrong before

- **Config checkpoints contain secrets.** `drush recipe` stores a checkpoint of the
  current configuration in `key_value` (`config.checkpoint.*`) before it applies a
  recipe. A recipe applied after the amazee.ai trial exists therefore stores the trial
  settings. The dump cleanup deletes all checkpoints. Always run the secrets check.
- **Olivero help block.** Do not import `block.block.olivero_help` in the site recipe:
  the help module is not installed, and the block logs "The help_block block plugin was
  not found" on every page.
- **Find similar tags breaks taxonomy automators.** With *Find similar tags* on, the
  automator asks the AI for similar existing tags. When there are none, the AI answers
  `[]`, which the AI Automators JSON decoder does not accept ("The response was not a
  valid JSON response. The response was: []"), and the whole automator fails. The guides
  keep it off for the page tags (step 02) and turn it off for the Image Tags automators
  of `ai_recipe_image_classification`. Worth reporting upstream.
- **AI log threads for AI Answers.** AI Answers runs its agent without a thread tag. The
  step 03 guide adds `ai_agents_runner_` to the thread tag prefixes of AI Logging, so
  every answer shows up as a thread.
- **Site name.** `drush site:install` overwrites the site name with "Drush Site-Install"
  unless you pass `--site-name`.
- **Theme blocks.** A recipe that installs a theme does not place the theme's blocks.
  The Site recipe imports the Olivero blocks explicitly (without the search blocks,
  because the search module is not installed).
- **Default providers.** `setupAiProvider` only sets default models when none are set,
  so the first provider wins. An OpenAI key added after the AI base is installed does
  not change the defaults.
- **Script tags in AI output.** The AI module's output filter removes `<script>` tags
  before guardrails run, so a script-tag guardrail never triggers. The output guardrail
  uses the JavaScript execution regex (`eval(`, `document.cookie`, and so on) instead.
- **Prompt injection guardrail.** It uses `restrict_to_topic`, which makes its own AI
  request with the default chat model. You can see that request in the AI logs.
- **AI Logging** is off after installation. Participants switch on request and
  response logging in the settings (step 1). Response logging is a separate setting.
- **Agent Edit button.** In the agent list it opens the workflow modeler, which logs
  PHP warnings. Link to `/admin/config/ai/tools-automation/agents/{id}/edit/form`
  instead.
- **`/admin/config/ai/tools`** (tools library) is not accessible even for the admin user.
  Do not use it in guides.
- **Test clones share the database.** A second checkout with the same DDEV project name
  uses the same database volume. `ddev delete` in the clone wipes the main site. Run
  `ddev catch-up` to restore it. Unlist the main project first with
  `ddev stop --unlist`.
- **Hostname.** On some machines, DDEV needs sudo to add the hostname to
  `/etc/hosts`. An agent cannot do that. Ask the user to run
  `sudo ddev-hostname drupal-ai-workshop.ddev.site 127.0.0.1`.
- **CKEditor AI button.** At a normal screen width the button disappears into the
  toolbar's overflow menu if it is placed last. The guide places it first.
- **Editor plugin form.** Checking an AI tool on the text format form triggers an AJAX
  rebuild that renames element IDs. In agent-browser, select checkboxes by `name`, one at a
  time, and re-query after each click.
- **Two "AI Assistant" buttons.** The CKEditor dropdown and the chatbot toggle have almost
  the same accessible name. Click the CKEditor one inside `.ck-toolbar` (`.ai-dropdown`).
- **Automator label.** The label field is inside a collapsed details element under
  Advanced Settings. Without a label, the automator appears without a name in the field
  widget action select, so the guide asks for a label.
- **Tone and Translate** CKEditor tools need a taxonomy vocabulary for their options. The
  guide skips them and uses *Modify with a prompt* instead.
- **Link pages by path**, not by node ID (for example `/about`), because node IDs depend
  on the install.
- **Autosave.** Drupal CMS saves form drafts (`autosave_form`). Reopening an edited page
  shows a *Resume editing / Discard* dialog. The dump cleanup empties that table.
- **amazee.ai timeouts.** Requests to the trial sometimes time out and are retried. A
  single failed run is not necessarily a bug.
- **Image recipes.** `ai_recipe_image_alt_text` (1.x-dev only) and
  `ai_recipe_image_classification` are applied in step 02. The workshop does not seed
  the Image Classification vocabulary.
  After the recipes, the media list shows the **+ Add media** button twice (cosmetic).
- **New Composer packages need a cache rebuild.** After `composer install`, Drupal only
  sees new modules after `drush cache:rebuild`. Until then, `drush recipe` fails with
  "is not a known module".
- **Two `ai_search` copies.** The AI project contains a deprecated `ai_search` submodule;
  step 03 adds the standalone project. After a cache rebuild, Drupal uses the standalone
  one (`modules/contrib/ai_search`).
- **Vectors are not in the dump.** They are in the DDEV Postgres service. `ddev catch-up`
  clears and rebuilds the `content_vector` index (about a minute, one embeddings request
  per page).
- **AI Answers blocks.** The Answer block shows a "Target id" on its add form that
  changes when the block is saved. The Question and Sources blocks use a select list of
  placed Answer blocks, so place the Answer block first. Turn off the Sources block's
  title and the Answer block's *Show references*, or the sources appear twice. The
  Answer block's reference view mode *Card* is more compact than *Teaser* in Olivero.
- **New pages are drafts.** The editorial workflow creates new pages as drafts; set
  *Change to: Published* before saving.
- **Agent tool settings** are in a dialog that opens with the tool card's *Configure*
  link (`a.dynamic-tool-modal`).
- **Flawed content was added on `01_setup` on purpose.** For step 04, the two pages with
  deliberate errors were changed in the site recipe on `01_setup` and merged into 02 and
  03, with regenerated dumps. The dumps were updated by writing `field_content` directly
  into `node__field_content` and `node_revision__field_content`, to avoid triggering the
  tags automator on save.
- **Content review and amazee.ai.** amazee.ai rejects OpenAI options in a criterion's
  provider config (`max_output_tokens`, `store`, `reasoning_effort`). The
  amazee.ai provider also builds its HTTP client without a timeout, so Drupal's default
  of 30 seconds applies instead of `ai.settings: request_timeout`; a review with the
  default `chat` model takes longer. The workshop rule therefore uses
  `amazeeio` / `claude-4-5-haiku` with an empty provider config (about 10 seconds).
  Saving the rule in the UI adds `max_tokens`, `temperature` and `top_p`, which amazee
  accepts, but it changes the criterion hash, so earlier records stop counting.
- **Do not use Apply in AI Content Review.** In 1.0.0-alpha3 (and the 1.x dev branch),
  `TextReplaceSuggestion::apply()` sets the whole target field to the suggested value.
  The agent suggests phrases, so applying one wipes the page text and saves a new
  revision. The guide uses Accept/Ignore, the improvement plan and manual correction.
  Upstream issue: [#3585854](https://git.drupalcode.org/project/ai_content_review/-/work_items/3585854)
  (confirmed there for alpha3 and 1.x). Related: #3585856, the next Save of the edit
  form fails after an Apply.
- **Review details.** The criterion link on the node's AI Review tab does not open its
  detail dialog; the same link in the edit form's Content Review sidebar panel does.
- **Chatbot in the browser.** The chat is a `deep-chat` web component. Send messages with
  `document.querySelector('deep-chat').submitUserMessage({text: '…'})`, and accept the
  Klaro consent (**Yes (this time)**) first.

## Next step

No further step is planned. Plan any new step with the user before building it.

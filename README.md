# SSW Website
The source code for the <a href="https://cornell-ssw.github.io/" target=_blank>
Cornell University Scientific Software Club</a>.

# Contributing
Is there a typo or something that could be clearer?  Please feel free to submit a Pull Request with a fix!

If you are submitting a fix for wording / grammar etc, refer to the [Hierarchy](#hierarchy) section below
for where the files you may need to edit are.  In general, it will probably be one of the `html` or `md`
documents in the top-level of the directory, or a page in the `meetings/` folder.

_Note_: Jekyll can be a little overwhelming, if you notice a flaw with the website but cannot / do not want
        to figure out where it actually is in the code, just submit an Issue indicating what needs to change :)

The remainder of this document is mostly to catalog how to manage the website as the officers change / the club ages.
If you want to increase those little green squares, the below should be enough to show what to edit where in your Pull Request.

# Compiling / Testing the Site

This website is built after each commit, but you can view your changes locally with ease.

1. Acquire the website source code:

   ```
   git clone --recursive https://github.com/cornell-ssw/cornell-ssw.github.io.git
   ```

   We are using [Reveal.js](https://github.com/hakimel/reveal.js) for some of the online slides, the
   `--recursive` will download the source for Reveal, and will not build correctly without it.

   If you already cloned the repository, you can perform the following from within the `cornell-ssw.github.io`
   folder to download the Reveal source code:

   ```
   git submodule update --init --recursive
   ```
2. Install the prerequisites for building with `jekyll`.  These directions are inlined from
   [here](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/)
   for convenience.

   - Open a terminal and verify you have Ruby 2.0 or higher:

     ```
     ruby --version
     ```

   - Use the ruby package manager to install `bundler`:

     ```
     gem install bundler
     ```

   - For convenience, we have included the relevant `Gemfile` in the top-level of this directory.
     This contains the `github-pages` gem url.

     ```
     # Navigate to the top level directory of this repository
     cd /path/to/cornell-ssw.github.io/
     # Install the tools needed for building GitHub Pages sites
     bundle install
     ```
3. Now that you have all of the necessary files, you can build the site locally.  Execute the command
   below from the top-level `cornell-ssw.github.io` folder:

   ```
   jekyll serve
   ```

   You can view the website by pasting the url `http://localhost:4000` into your favorite internet
   browser.  Any updates you make to the site will be re-generated on the fly, but if you update
   the page you are currently viewing in the browser you will need to refresh (usually just
   `ctrl`+`R` or `cmd`+`R`).
4. When you are finished running the site locally, use `ctrl`+`c` to end the `jekyll serve` command.
   The site `http://localhost:4000` should say Page Not Found or something similar if you have actually
   terminated the server.

# Hierarchy

We use the excellent [Jekyll](https://jekyllrb.com/) scripting language to coordinate various components
of the website.  You should generally not need to touch any of these files to submit bugfixes, but for
clarity the relevant scripting files are primarily in folders starting with an `_`.

```
cornell-ssw.github.io/
│
├─── _data/
│     │
│     ├─── meetings.yml # Where the links are read from for the 'Meetings' page.
│     └─── navpages.yml # The names and links for the Navbar at the top of the page.
│
├─── _includes/
│     │
│     └─── Modular html pages for the meta / navbar etc.
│
├─── _layouts/
│     │
│     └─── Page appearance prototypes.  Usually, just use `post` for meeting notes
│          and `slide` for Reveal.js slides.
│
├─── css/
│     │
│     └─── Various styling elements for the appearance of the pages.
│
├─── meetings/
│     │
│     └─── Where the meeting notes for each week are stored. Linked to from `meetings.yml`.
│
└─── slides/
      │
      └─── Where the Reveal.js slides are stored.  PDF files are hosted elsewhere to avoid
           tracking them with git.
```

# Writing new Pages

If you are tasked with generating new pages, there are three forms.  Please note that when adding
new pages, the file extension determines how `jekyll` will process it.

1. Raw html code, e.g. `index.html`.  While writing raw html code can be cumbersome, it gives
   you the ability to use `jekyll` to script the output (see the bottom of `index.html`).
2. Markdown, e.g. `cluster.md`.  Our site is parsed with Kramdown, so there may be subtle
   differences in the Markdown you know and the one that is displayed here.  Just build
   the site locally and you will see any differences, but for general purposes you will
   not have issues.

   Note that you are, as with any other Markdown, able to embed raw html code directly
   if you need a format / structure that Markdown does not support.
3. Markdown based slides!  You can write slides for a potential presentation using Reveal.js
   quite easily in a markdown document.  LaTeX equations can be rendered, and much more.

   Refer to a sample in the `slides/` directory for how to format things.

## Meeting Notes

Meeting notes are a little special.  You will need to create the appropriately named (e.g. the date)
markdown document in `meetings/`, as well as write the appropriate links / bullets in `_data/meetings.yml`.
Just refer to a previously created markdown document / the other information in `_data/meetings.yml` to
see how to link everything up.  The site will parse the yml document and add to the table on the Meetings page.

### Heading Information at the Top

Of note is the required heading section for each meeting notes page at the top of the document.  The
section enclosed in the opening and closing `---` is parsed by `jekyll` as metadata.  For example:

```
---
title: A Pythonic Whirlwind
layout: post
speakers:
  - speaker:
    name: David Bindel
    affil: Cornell University
    url: http://www.cs.cornell.edu/~bindel/
---
```

If there are no guest speakers, simply omit that part.  If there are more than one speaker,
add another bullet.  In the following we will add a new speaker to the above

```
---
title: A Pythonic Whirlwind
subtitle: For Vikings of All Shapes and Sizes
layout: post
speakers:
  - speaker:
    name: David Bindel
    affil: Cornell University
    url: http://www.cs.cornell.edu/~bindel/
  - speaker:
    name: Leiv Eiriksson
    affil: Vinland University
---
```

You must be careful to

1. Indent everything correctly, `jekyll` is particularly sensitive in this respect.
2. Include a `title`.
    - Long titles can break the format, use `subtitle` if needbe.
3. All speakers must have an affiliation.

If the speaker does not have a website, or does not want it linked, just omit the `url` portion.

### Meeting Notes Format

After the heading, a brief bullet list as an overview.  Following, the meeting notes or abstract
of the talk given.

It is useful to point out that you can link to sections (headings in markdown start with `#`)
with `[link text for viewer](#the-section-title)`.  So the viewer of the page will see that
`link text for viewer` is a hyper-link, and it will navigate to the same page (in html, this
is a different `#` than markdown) to the section `The Section Title`.  Links are always lower
case, and spaces are converted to dashes.

### Getting Meetings to Link from the Meetings Page

Now that you have created a new meeting page in `meetings/`, edit the document `_data/meetings.yml`
to link it.  We are listing the meetings with the most recent at the top, the oldest at the bottom.
YAML (`yml`) documents are equally sensitive to syntax / spacing, but if you simply copy-paste you
shouldn't run into trouble.  As an example

```
# Week 1
################################################################################
-
  date: 2016-09-12
  info: <a href="/meetings/2016-09-12">Welcome to SSW</a>
  brief:
    - Discussion of the goals of the club.
    - Introduction to Unix and Windows shell.
```

`#` is a comment, the first line has a `-`, and the remaining information is indented by
two spaces.  The `brief` is the only section that is capable of bullet lists.  This
document is written with html, so if you want something to show up with say bold text
or code you will need `<b>bold text</b>` or `<code>some code</code>`.

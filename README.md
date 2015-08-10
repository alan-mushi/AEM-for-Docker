# AEM for Docker

A fully working, pretty customizable AEM (Author & Publish) integration for Docker.
Other versions exits but this is a demo-free with automatic configuration at startup Docker images.

## How to use

For licensing reasons I can't put AEM stuff so you will need to build the images yourself!
I used `centos:6.6` as base image but you should be able to change it easily.

### Regular start

Adding necessary files is easy, just look for the empty files and replace them:

```
$ find . -size 0
```

Add the AEM hotfixes to the `images/{author,publish}/hotfixes` directory and add the hotfixes names to the `hotfixes.{author,publish}` file.

Build the images:

```
$ docker-compose build
```

Before running the images look closely to `env/*_regular_start.env` and `images/{author,publish}/README.md`.
The files in the env directory are used as a way to dynamically configure the AEM instances at startup.
For the default scenario don't change them, see the following section for rollback.

Finally, add your AEM bundle files to `volumes/aem-packages/` and fill in the `list.*` files.
`list_last.author` is meant for the last bundle to install at the end of the configuration (e.g. a bundle that changes admin credentials to a value you don't need to know).

You can automate the AEM instances start order by watching signals they will create in `volumes/signals/...`, you can also do this by reading the container output log.
The signal here is the creation of a file, checkout the end of `images/publish/web_conf.sh` for more details.

Start AEM in this order:

```
$ docker-compose up -d publish
## wait for AEM publish to signal

$ docker-compose up -d --no-recreate author
## wait for AEM author to signal
```

It's ready, you can know access AEM Author on 4502 and Publish on 4503.

### Rollback segmentstores

Segmentstores are the "data repository" for both AEM.
The catch is that one build/first-run, of either AEM Author or Publish, produces the compatible segmentstores.
This first run happens during the build of the image (hotfixes installation requires a restart of AEM).
Thus using segmentstores from a previous build to restore data won't work!

Now, to rollback segmentstores from the same build you need to modify which env file docker-compose should use.
For a rollback scenario checkout the `env/{author,publish}_reuse.env` files (they don't re-do the configuration and don't override existing segmentstores).

## Context

For my current internship, at Atos Open Source Center, I had to put AEM on Docker.
It turns out it's not as easy as it seems because AEM is not meant for it.

Thanks to Lee Namba and Tiago Pires Gomes for allowing me to share this implementation.

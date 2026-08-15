# Attribution

Mesa bundles a normalised copy of a third-party exercise dataset and loads that
project's exercise media remotely. The two are under **different terms**, and
the difference is the reason the app is built the way it is.

## Exercise dataset — MIT

Source: [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
Vendored at commit `7455efae41b330c265e7cd4b78dfa848e7ce5ebd`.

The dataset's code, structure and instruction text are MIT licensed. Mesa ships
a derived copy in `assets/catalog/exercises.json`: English only, cardio records
removed, muscle and equipment vocabularies normalised, load models derived.
`tools/build_catalog/` is the pipeline that produces it, and both its inputs and
its outputs are committed so the build is reproducible offline.

```
MIT License

Copyright (c) 2026 Hasan Emir Yıldırım

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation and data files (the "Software"),
to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

------------------------------------------------------------------------------
MEDIA EXCEPTION
------------------------------------------------------------------------------

The MIT license above covers ONLY the code, tooling, dataset structure, and
instruction text/translations in this repository.

It DOES NOT cover the exercise media in the `images/` and `videos/`
directories. That media is © Gym visual (https://gymvisual.com/) and is
included here with the rights holder's written permission, at 180×180
resolution, and must retain the attribution "© Gym visual —
https://gymvisual.com/". Its use and reuse are governed by Gym visual's Terms
& Conditions (https://gymvisual.com/content/3-terms-and-conditions-of-use) and
by `NOTICE.md` in this repository — NOT by the MIT license above. Cloning this
repository does not grant you any license to the media; obtain your own from
Gym visual.
```

## Exercise media — © Gym visual, NOT MIT

The thumbnails and animation GIFs are **© [Gym visual](https://gymvisual.com/)**,
redistributed in the dataset repository with permission at 180×180. They are not
covered by the MIT licence above, and reuse is governed by Gym visual's own
[terms](https://gymvisual.com/content/3-terms-and-conditions-of-use), which
expect you to obtain your own licence.

Note that the media exception is explicit that the attribution string
`© Gym visual — https://gymvisual.com/` **must be retained**, and that cloning
the dataset grants no licence to the media. That is an obligation from the
licence itself, not a courtesy — which is why the string is a required field on
every catalogue record and a test fails if any record is missing it.

What this app does about it:

- Media is **never bundled in the APK and never re-hosted**. It loads on demand
  from the source repository's raw URLs, pinned to the same commit as the data,
  and is cached on device by `cached_network_image`.
- Every record's `attribution` string — `© Gym visual — https://gymvisual.com/` —
  is displayed on the exercise detail screen, alongside the image.
- All media access goes through one constant, `CatalogConfig.mediaEnabled` in
  `lib/core/constants/catalog_config.dart`.

> **Before distributing this app, read §5.1 of `docs/caderno-de-encargos.md`.**
>
> Mesa is a personal, single-user app running on its owner's own device, which
> is personal use rather than redistribution. The moment it reaches anyone
> else's device — the Play Store, an internal testing track, a shared APK — the
> media stops being personal use and Gym visual's terms apply. At that point
> either obtain a media licence, or set `CatalogConfig.mediaEnabled` to `false`
> and ship without images. Keeping every media request behind that one constant
> is what makes this a one-line change; that is the constant's whole purpose.

## Flutter and package dependencies

Their own licences apply; run `flutter pub deps` for the current tree.

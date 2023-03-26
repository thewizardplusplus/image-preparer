# Image Preparer

![](docs/screenshot.png)

The utility for image preparation.

## Features

- search of images:
  - recursive search (optionally);
  - filtering by a pattern of image filenames (uses a name pattern of the `find` tool);
- resizing of images larger than the specified size with the [Lanczos](https://en.wikipedia.org/wiki/Lanczos_resampling) filter;
- optimization of images (optionally):
  - via the [pngquant](https://pngquant.org/) tool;
  - via the [OptiPNG](http://optipng.sourceforge.net/) tool.

## Requirements

- [ImageMagick](http://www.imagemagick.org/) >=6.7.7-10, <7.0;
- [pngquant](https://pngquant.org/) >=2.9.1, <3.0;
- [OptiPNG](http://optipng.sourceforge.net/) >=0.7.6, <1.0.

## Usage

```
$ image_preparer.bash -v | --version
$ image_preparer.bash -h | --help
$ image_preparer.bash [options] [<path>]
```

Options:

- `-v`, `--version` &mdash; show the version;
- `-h`, `--help` &mdash; show the help;
- `-n PATTERN`, `--name PATTERN` &mdash; a pattern of image filenames (uses a name pattern of the `find` tool; default: `*.png`);
- `-r`, `--recursive` &mdash; recursive search of images;
- `-w WIDTH`, `--width WIDTH` &mdash; a maximum width of images (default: `640`);
- `--no-optimize` &mdash; don't optimize images.

Arguments:

- `<path>` &mdash; base path to images (default: `.`).

## License

The MIT License (MIT)

Copyright &copy; 2018, 2023 thewizardplusplus

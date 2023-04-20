# Change Log

## [v1.3.0](https://github.com/thewizardplusplus/image-preparer/tree/v1.3.0) (2023-04-20)

Add the mode without processing of images and improve logging of image changes.

- the mode without processing of images, only with search of them and check of their size;
- logging of image changes:
  - logging of an image number and name at the beginning of processing;
  - fix the bug with zero original size on logging of a change of image sizes;
  - remove redundant logging:
    - of a total change of image sizes;
    - of a global total change of image sizes.

## [v1.2.0](https://github.com/thewizardplusplus/image-preparer/tree/v1.2.0) (2023-04-18)

Support optimization of images in JPEG format; add an optimization step via the `advpng` tool from the [AdvanceCOMP](http://www.advancemame.it/) project; improve search of images.

- search of images:
  - fix the bug with ignoring files with extensions in uppercase;
  - support Perl-compatible regular expressions (PCREs) in a pattern of image filenames;
- optimization of images:
  - in PNG format:
    - via the `advpng` tool from the [AdvanceCOMP](http://www.advancemame.it/) project;
  - in JPEG format:
    - via the [jpegoptim](https://github.com/tjko/jpegoptim) tool.

## [v1.1.0](https://github.com/thewizardplusplus/image-preparer/tree/v1.1.0) (2023-03-29)

Improve resizing of images and add logging of image changes.

- resizing of images:
  - make resizing of images optional;
  - skip images with an allowed resolution;
- logging of image changes:
  - logging of a change of an image resolution on resizing;
  - logging of a change of an image size:
    - on the following operations:
      - resizing;
      - optimization;
    - logging of a total change of image sizes:
      - total change after all the optimization steps;
      - total change after both resizing and optimization operations;
      - total change for all images together;
    - logging of a saved image size in percent.

## [v1.0.0](https://github.com/thewizardplusplus/image-preparer/tree/v1.0.0) (2023-03-28)

The major version.

- Fix the black color in log messages

_(The change log is compared to the release candidate of the major version.)_

## v1.0.0-rc (2018-02-04)

The release candidate of the major version. It is part of the version 1.5 of the project Wizard Blog New.

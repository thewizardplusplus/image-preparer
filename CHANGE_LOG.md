# Change Log

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

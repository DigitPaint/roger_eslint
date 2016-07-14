Roger ESLint
============

[![Build Status](https://travis-ci.org/DigitPaint/roger_eslint.svg)](https://travis-ci.org/DigitPaint/roger_eslint)


Lint JavaScript files from within Roger. This plugin uses [eslint](http://eslint.org/). If present, .eslintrc in your project will be used. If not, eslint will walk the directory tree upwards until a .eslintrc file is found. 

## Installation
* Install eslint using npm: ```npm install eslint -g```

* Add ```gem 'roger_eslint'``` to your Gemfile

* Add this to your Mockupfile:
```
mockup.test do |t|
  t.use :eslint
end
```

* (Optional) put a .eslintrc in your project's root directory.

## Running
Execute ```roger test eslint```.

## License

This project is released under the [MIT license](LICENSE).

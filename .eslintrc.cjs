module.exports = {
    "env": {
        "browser": true,
        "commonjs": true,
        "es6": true,
        "node": true
    },
    "globals": {
        "Atomics": "readonly",
        "SharedArrayBuffer": "readonly"
    },
    "parserOptions": {
        "ecmaVersion": 2018
    },
    "rules": {
      "import/no-unresolved": "error"
    },
    "parser": "eslint-plugin-coffee",
    "plugins": ["coffee"],
    "extends": [
      "eslint:recommended",
      "plugin:coffee/eslint-recommended",
      "plugin:coffee/import",
      "plugin:coffee/disable-incompatible"
    ]
};

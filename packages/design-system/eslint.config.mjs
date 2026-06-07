import { config } from "@lexicon/eslint-config/base";

/** @type {import("eslint").Linter.Config} */
export default [
  ...config,
  {
    rules: {
      "react-hooks/exhaustive-deps": "off",
    },
  },
];

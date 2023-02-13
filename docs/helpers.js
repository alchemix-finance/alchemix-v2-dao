const ADMIN_FUNCTIONS = [
];

module.exports = {
  filter: (name) => !ADMIN_FUNCTIONS.includes(name),

  /**
   * Formats a description so that it renders properly in markdown. All descriptions in the code are horizontally
   * aligned to make the description easier to read. This along with new lines and return carriages pose a problem in
   * markdown because they render differently than expected. New lines, carriage returns, and spaces are replaced with
   * a single space.
   *
   * @param options The handlebar options.
   * @returns {*} The formatted string.
   */
  formatDescription: function (options) {
    return options
      .fn(this)
      .trim()
      .replace(/[\r\n ]+/gm, " ");
  },

  /**
   *
   * @param a
   * @param b
   * @returns {*}
   */
  gt: function (a, b) {
    const next = arguments[arguments.length - 1];
    return a > b ? next.fn(this) : next.inverse(this);
  },
};

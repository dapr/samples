const { createLogger, format, transports, config } = require("winston");
const { combine, timestamp, label, printf } = format;

const daprFormat = printf(({ level, message, label, timestamp }) => {
  return `${label} == time="${timestamp}" level=${level} msg="${message}"`;
});

const options = {
  console: {
    level: "debug",
    handleExceptions: true,
    json: false,
    colorize: true,
  },
};

const logger = createLogger({
  format: combine(label({ label: "PROVIDER" }), timestamp(), daprFormat),
  levels: config.npm.levels,
  transports: [new transports.Console(options.console)],
  exitOnError: false,
});

module.exports = logger;

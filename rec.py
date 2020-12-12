import argparse
import datetime
import json
import logging
import os
import subprocess


class RecException(Exception):
    def __init__(self, msg):
        super().__init__(msg)


def get_logger(name):
    handler = logging.StreamHandler()
    handler.setLevel(logging.DEBUG)
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(funcName)s: %(message)s"))
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    logger.addHandler(handler)
    logger.propagate = False

    return logger


def rec(args, config, logger):
    radigo_path = "/usr/local/bin" if args.debug else "/bin"
    ffmpeg_path = "/usr/local/bin" if args.debug else "/usr/bin"

    channel = config["channel"]
    date_at = get_date(config["week_of_day"])
    start = "{}{}00".format(date_at.strftime("%Y%m%d"), config["time_at"])
    file_name = "{}-{}.aac".format(start, channel)

    aac_file = os.path.join("output", file_name)
    if not os.path.exists(aac_file):
        run = [
            os.path.join(radigo_path, "radigo"),
            "rec",
            "-id=" + config["channel"],
            "-s=" + start
        ]
        result = subprocess.run(run, encoding='utf-8', stderr=subprocess.PIPE)
        if result.returncode != 0:
            raise RecException(result.stderr)

    date_str = date_at.strftime("%Y-%m-%d")
    mp4_file = os.path.join(args.output, f"{args.program}_{date_str}.m4b")
    logger.debug(mp4_file)
    if os.path.exists(mp4_file):
        os.remove(mp4_file)
    run = [
        os.path.join(ffmpeg_path, "ffmpeg"),
        "-i", aac_file,
        "-f", "mp4",
        "-b:a", "47k",
        "-metadata", "artist=" + config["artist"],
        "-metadata", "title=" + date_str + " ON AIR",
        "-metadata", "album=" + config["album"],
        mp4_file
    ]
    result = subprocess.run(run, encoding='utf-8', stderr=subprocess.PIPE)
    if result.returncode != 0:
        raise RecException(result.stderr)


def get_date(target):
    wd_idx = ("mon", "tue", "wed", "thu", "fri", "sat", "sun")

    if target not in wd_idx:
        raise RecException(f"Invalid target({target})")
    idx = wd_idx.index(target)

    today = datetime.date.today()
    weekday = today.weekday()
    if idx <= weekday:
        days = weekday - idx
    else:
        days = 7 - idx + weekday

    return today - datetime.timedelta(days=days)


def main():
    logger = get_logger(__name__)

    # コマンドライン引数を解析
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config", default="/config.json", help="path of config file.")
    parser.add_argument("-o", "--output", default="/output", help="path of output directory.")
    parser.add_argument("-d", "--debug", action='store_true', help="debug mode")
    parser.add_argument("program")
    args = parser.parse_args()

    with open(args.config, "r") as f:
        config = json.load(f)

    if args.program in config:
        try:
            rec(args, config[args.program], logger)
            logger.info("success")
        except RecException as ex:
            parser.error(ex)
    else:
        parser.error(f"{args.program} not found.")


if __name__ == "__main__":
    main()

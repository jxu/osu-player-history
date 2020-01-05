# Three versions of the pp page:
# osu.ppy.sh/p/pp (original site)
# osu.ppy.sh/rankings/osu/performance (new site redesign)
# old.ppy.sh/p/pp (legacy site, not many archives so ignore)

# Manually remove some pages:
# TODO: remove automatically
# Nov 2013 to Jan 2014: pp broke
# https://web.archive.org/web/20140126153042/http://osu.ppy.sh/news/73929298672
# Remove 20140125 and 20140126
# Replace 20181214084650 with 20181214085715 due to cheater
# Remove 20190805: archive.org error

from datetime import date, timedelta
import requests
import os

OLDSITE_START_DATE = date(2012, 4, 21)  # earliest snapshot
OLDSITE_END_DATE = date(2018, 3, 23)  # last snapshot before redirect
NEWSITE_START_DATE = date(2017, 6, 17)


def query_ia(start_date, end_date, base_site):
    """Iterate through [start_date, end_date] and saves snapshots"""
    query_date = start_date
    snapshot_dates = set()

    while query_date <= end_date:
        query_date_str = query_date.strftime("%Y%m%d")

        # Use feature where putting in the date str redirects to closest
        # date snapshot
        # Can make requests async, but don't to not generate too much activity
        query_url = f"https://web.archive.org/web/{query_date_str}/{base_site}"
        r = requests.get(query_url)
        snapshot_timestamp = ''.join(c for c in r.url if c.isdigit())
        snapshot_date = snapshot_timestamp[:8]

        print(f"Queried {query_date}, got snapshot date {snapshot_date}")

        if snapshot_date not in snapshot_dates:
            snapshot_dates.add(snapshot_date)
            snapshot_path = f"snapshots/{snapshot_date}.html"
            print("Writing", snapshot_path)
            with open(snapshot_path, 'w') as f:
                f.write(r.text)

        query_date += timedelta(days=1)


def main():
    # hardcoded directory oh well
    os.makedirs("snapshots", exist_ok=True)

    query_ia(OLDSITE_START_DATE, OLDSITE_END_DATE, "osu.ppy.sh/p/pp")
    # Will overwrite a few overlapping snapshots
    query_ia(NEWSITE_START_DATE, date.today(),
             "osu.ppy.sh/rankings/osu/performance")

if __name__ == '__main__':
    main()

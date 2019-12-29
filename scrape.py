# Three versions of the pp page:
# osu.ppy.sh/p/pp (original site)
# osu.ppy.sh/rankings/osu/performance (new site redesign)
# old.ppy.sh/p/pp (legacy site, not many archives so ignore)

from datetime import date, timedelta
import requests
import os

OLDSITE_START_DATE = date(2012, 4, 21)  # earliest snapshot
OLDSITE_END_DATE = date(2018, 3, 23)  # last snapshot before redirect
NEWSITE_START_DATE = date(2017, 6, 17)


query_date = OLDSITE_START_DATE
snapshot_dates = set()
os.makedirs("snapshots", exist_ok=True)

while query_date < date.today():
    query_date_str = query_date.strftime("%Y%m%d")

    # Query old site or new site based on query date
    if query_date < NEWSITE_START_DATE:
        base_site = "https://osu.ppy.sh/p/pp"
    else:
        base_site = "osu.ppy.sh/rankings/osu/performance"

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



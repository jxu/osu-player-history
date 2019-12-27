# Three versions of the pp page:
# osu.ppy.sh/p/pp (original site)
# osu.ppy.sh/rankings/osu/performance (new site redesign)
# old.ppy.sh/p/pp (legacy site, not many archives so ignore)

from datetime import date, timedelta
import requests


OLDSITE_START_DATE = date(2012, 4, 21)  # earliest archive
OLDSITE_END_DATE = date(2018, 4, 1)  # redirect from mar 28, 2018 onwards
NEWSITE_START_DATE = date(2017, 6, 17)

# query Internet Archive for nearest available snapshot
def query_archive(url, query_date):
    query_date_str = query_date.strftime("%Y%m%d")
    payload = {"url": url, "timestamp": query_date_str}

    r = requests.get("https://archive.org/wayback/available",
                     params=payload)
    json_closest = r.json()["archived_snapshots"]["closest"]
    print(payload)
    print(r.json())

    assert json_closest["available"] and json_closest["status"] == "200"
    snapshot_date = json_closest["timestamp"][:8]
    snapshot_url = json_closest["url"]
    return snapshot_date, snapshot_url


query_date = OLDSITE_START_DATE
query_date = date.today() - timedelta(days=30)
archive_links = dict()  # one dict for oldsite and newsite

while query_date < date.today():
    print("Querying", query_date)

    snapshot_date = snapshot_url = None

    # Query old site or new site based on query date
    if query_date < OLDSITE_END_DATE:
        snapshot_date, snapshot_url = \
            query_archive("osu.ppy.sh/p/pp", query_date)

    if query_date >= NEWSITE_START_DATE:
        snapshot_date, snapshot_url = \
            query_archive("osu.ppy.sh/rankings/osu/performance", query_date)

    # at least one site was queried
    assert snapshot_date is not None
    archive_links[snapshot_date] = snapshot_url

    query_date += timedelta(days=1)

print(archive_links)

#for archive_link in oldsite_archive_links:
#    r = requests.get(archive_link)

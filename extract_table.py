# Old table parsing info
# 20120614: removed pp distance to next player
# 20140209: removed score rank

from bs4 import BeautifulSoup
import os
import csv

SNAPSHOTS_DIR = "snapshots"


# stupid locale stuff
def clean_int(s):
    return ''.join(c for c in s if c not in ",.\xa0")

def clean_float(s):
    return float(s.replace('\xa0', '').replace('%', '').replace(',', '.'))


def extract_table_info(html_doc, date_str):
    soup = BeautifulSoup(html_doc, "lxml")

    result = []

    # old site table
    table_soup = soup.find("table", class_="beatmapListing")
    if table_soup:
        table_rows = table_soup.find_all("tr")
        table_header, player_rows = table_rows[0], table_rows[1:]
        # unused for now
        table_has_score_rank = "Score" in table_header.get_text()

        for player_row in player_rows:
            #print(player_row)

            row_dict = dict()
            row_dict["date"] = date_str

            # Get two letter country code from flag img url
            img_flag = player_row.find("img", class_="flag")
            img_url = img_flag["src"]

            assert img_url.endswith(".gif")
            row_dict["country"] = img_url.split('/')[-1][:-4]

            player_url = player_row.find("a")["href"]
            row_dict["username"] = player_row.find("a").text
            row_dict["id"] = int(player_url.split('/')[-1])

            cells = player_row.find_all("td")

            row_dict["rank"] = int(cells[0].get_text()[1:])
            row_dict["accuracy"] = clean_float(cells[2].get_text())

            # playcount and level
            player_row_pl = cells[3].get_text().split(' ')
            row_dict["playcount"] = clean_int(player_row_pl[0])
            pp_text = cells[4].get_text().strip()
            row_dict["pp"] = clean_int(pp_text.split("pp")[0])

            result.append(row_dict)

        return result

    # new site table
    table_soup = soup.find("table", class_="ranking-page-table")
    if table_soup:


        table_rows = table_soup.find_all("tr")
        player_rows = table_rows[1:]

        for player_row in player_rows:
            row_dict = dict()
            row_dict["date"] = date_str

            cells = player_row.find_all("td")

            row_dict["rank"] = int(cells[0].get_text().strip()[1:])

            # Starting from 20180317, country is also linked in cell
            player_url = cells[1].find_all("a")[-1]["href"]
            row_dict["id"] = int(player_url.split('/')[-1])

            flag_span = cells[1].find("span", class_="flag-country")
            flag_style = flag_span["style"]
            str_idx = flag_style.find(".png")

            row_dict["country"] = flag_style[str_idx-2:str_idx].lower()
            row_dict["username"] = cells[1].get_text().strip()
            row_dict["accuracy"] = clean_float(cells[2].get_text().strip())
            row_dict["playcount"] = clean_int(cells[3].get_text().strip())
            row_dict["pp"] = clean_int(cells[4].get_text().strip())

            result.append(row_dict)

        return result

    # Somehow not new site or old site
    raise Exception("Can't find table")


def main():
    all_rows = []

    for snapshot_filename in sorted(os.listdir(SNAPSHOTS_DIR)):
        date_str = os.path.splitext(snapshot_filename)[0]
        #if date_str < "20170617": continue  # testing

        snapshot_path = os.path.join(SNAPSHOTS_DIR, snapshot_filename)
        print(snapshot_path)

        with open(snapshot_path) as f:
            html_doc = f.read()
            extracted_rows = extract_table_info(html_doc, date_str)
            all_rows.extend(extracted_rows)

    col_names = ("date", "rank", "country", "username", "id", "accuracy",
                 "playcount", "pp")

    with open("player_history.csv", 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=col_names)

        writer.writeheader()
        writer.writerows(all_rows)


if __name__ == "__main__":
    main()
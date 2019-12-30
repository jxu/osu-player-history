# Old map table parsing info
# 20120614: removed pp distance to next player
# 20140209: removed score rank

from bs4 import BeautifulSoup

def comma_int(s): return int(s.replace(',', ''))


def extract_table_info(html_doc):
    soup = BeautifulSoup(html_doc, "lxml")
    table = soup.find("table", class_="beatmapListing")
    table_rows = table.find_all("tr")
    table_header, player_rows = table_rows[0], table_rows[1:]
    table_has_score_rank = "Score" in table_header.get_text()

    for player_row in player_rows:
        #print(player_row)

        row_dict = dict()

        # Get two letter country code from flag img url
        img_flag = player_row.find("img", class_="flag")
        img_url = img_flag["src"]

        assert img_url.endswith(".gif")
        row_dict["country"] = img_url.split('/')[-1][:-4]

        player_url = player_row.find("a")["href"]
        row_dict["name"] = player_row.find("a").text
        row_dict["id"] = int(player_url.split('/')[-1])

        player_row_cells = player_row.find_all("td")

        row_dict["rank"] = int(player_row_cells[0].get_text()[1:])
        row_dict["accuracy"] = float(player_row_cells[2].get_text()[:-1])
        player_row_playcount_level = player_row_cells[3].get_text().split(' ')
        row_dict["playcount"] = comma_int(player_row_playcount_level[0])
        pp_text = player_row_cells[4].get_text().strip()
        row_dict["pp"] = comma_int(pp_text.split("pp")[0])


        if table_has_score_rank:
            pass  # if use columns to the right of pp


        print(row_dict)


with open("snapshots/20120421.html") as f:
    html_doc = f.read()
    extract_table_info(html_doc)

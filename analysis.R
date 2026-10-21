# ------------------------------------------------------------------
# Who actually cosponsors maternal health, deaf and hard of hearing,
# and disability bills in the 119th Congress
#
# analysis.R
#
# Reads data/ (built by build_data.py from govinfo BILLSTATUS bulk
# data) and writes the tables in output/, the figures in figures/, and
# the graph JSON that docs/index.html renders.
#
# Run in RStudio: open this file, Session > Set Working Directory >
# To Source File Location, then Source (Ctrl+Shift+S).
# ------------------------------------------------------------------

needed <- c("tidyverse", "igraph", "jsonlite", "scales")
missing <- needed[!needed %in% rownames(installed.packages())]
if (length(missing) > 0) install.packages(missing)
library(tidyverse); library(igraph); library(jsonlite); library(scales)

dir.create("output", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
dir.create("docs", showWarnings = FALSE)

bills   <- read_csv("data/topic_bills.csv",      show_col_types = FALSE, col_types = cols(.default = "c"))
cospon  <- read_csv("data/topic_cosponsors.csv", show_col_types = FALSE, col_types = cols(.default = "c"))
members <- read_csv("data/members.csv",          show_col_types = FALSE, col_types = cols(.default = "c"))

topics <- c(maternal = "Maternal health", deaf_hoh = "Deaf and hard of hearing", disability = "Disability")
pal_party <- c(D = "#2166ac", R = "#b2182b", I = "#4d9221", ID = "#4d9221", L = "#4d9221")

bills <- bills %>%
  mutate(chamber = if_else(str_starts(bill_type, "H"), "House", "Senate"),
         n_cosponsors = as.integer(n_cosponsors),
         introduced_date = as.Date(introduced_date))

# Abortion-policy bills (bans, mifepristone restrictions, pregnancy resource center funding) are
# tagged in the data but kept out of the maternal health network. They are a different fight with
# a different coalition, and folding them in would swamp the maternal care bills on the Republican
# side. They are listed in output/abortion_policy_bills.csv for completeness.
abortion_bills <- bills %>% filter(str_detect(topics, "abortion"))
write_csv(abortion_bills %>% select(bill_id, title, sponsor_name, n_cosponsors, introduced_date, url), "output/abortion_policy_bills.csv")
bills  <- bills %>% filter(!str_detect(topics, "abortion"))
cospon <- cospon %>% filter(bill_id %in% bills$bill_id)

# Long table: one row per (bill, topic)
bill_topics <- bills %>%
  separate_longer_delim(topics, "|") %>%
  rename(topic = topics)

# Signers: sponsor plus every cosponsor who did not withdraw
signers <- bind_rows(
  bills %>% transmute(bill_id, bioguide = sponsor_bioguide, role = "sponsor"),
  cospon %>% filter(withdrawn_date == "" | is.na(withdrawn_date)) %>%
    transmute(bill_id, bioguide, role = if_else(is_original == "True", "original cosponsor", "cosponsor"))
) %>% filter(bioguide != "") %>% distinct(bill_id, bioguide, .keep_all = TRUE) %>%
  left_join(members %>% select(bioguide, full_name, party, state, district, chamber), by = "bioguide")

# ---- 1. Bill-level: size and bipartisanship ----------------------
bill_summary <- signers %>%
  group_by(bill_id) %>%
  summarise(signers = n(),
            dem = sum(party == "D"), rep = sum(party == "R"), ind = sum(!party %in% c("D", "R")),
            .groups = "drop") %>%
  mutate(bipartisan = dem > 0 & rep > 0,
         minority_share = pmin(dem, rep) / signers) %>%
  right_join(bills %>% select(bill_id, bill_type, number, title, chamber, topics, sponsor_name, sponsor_party, introduced_date, latest_action, url, veteran_related), by = "bill_id") %>%
  mutate(across(c(signers, dem, rep, ind), ~ replace_na(.x, 0)),
         bipartisan = replace_na(bipartisan, FALSE)) %>%
  arrange(desc(signers))
write_csv(bill_summary, "output/bill_summary.csv")

topic_summary <- bill_topics %>%
  left_join(bill_summary %>% select(bill_id, signers, bipartisan, dem, rep), by = "bill_id") %>%
  group_by(topic) %>%
  summarise(bills = n(),
            house_bills = sum(chamber == "House"), senate_bills = sum(chamber == "Senate"),
            median_signers = median(signers), mean_signers = round(mean(signers), 1),
            bipartisan_bills = sum(bipartisan), pct_bipartisan = percent(mean(bipartisan), 1),
            dem_sponsored = sum(sponsor_party == "D"), rep_sponsored = sum(sponsor_party == "R"),
            .groups = "drop") %>%
  mutate(topic = topics[topic])
write_csv(topic_summary, "output/topic_summary.csv")

# ---- 2. Member-level: who signs, who bridges ---------------------
member_topic <- signers %>%
  inner_join(bill_topics %>% select(bill_id, topic), by = "bill_id") %>%
  group_by(bioguide, topic) %>%
  summarise(bills_signed = n(), bills_sponsored = sum(role == "sponsor"), .groups = "drop")

# Cross-party share: of the OTHER signers on the bills this member signed, what share are from the other party
cross_party <- signers %>%
  inner_join(signers %>% select(bill_id, other = bioguide, other_party = party), by = "bill_id", relationship = "many-to-many") %>%
  filter(bioguide != other, party %in% c("D", "R")) %>%
  group_by(bioguide) %>%
  summarise(cross_party_share = mean(other_party != party & other_party %in% c("D", "R")), .groups = "drop")

# Member projection per chamber: edge weight = number of topic bills both signed
project_members <- function(sig) {
  inc <- sig %>% distinct(bill_id, bioguide) %>% mutate(v = 1L) %>%
    pivot_wider(names_from = bill_id, values_from = v, values_fill = 0L)
  m <- as.matrix(inc[, -1]); rownames(m) <- inc$bioguide
  adj <- m %*% t(m); diag(adj) <- 0
  g <- graph_from_adjacency_matrix(adj, mode = "undirected", weighted = TRUE)
  g
}

member_metrics <- list()
graphs <- list()
for (ch in c("House", "Senate")) {
  sig <- signers %>% filter(chamber == ch)
  g <- project_members(sig)
  V(g)$party <- members$party[match(V(g)$name, members$bioguide)]
  graphs[[ch]] <- g
  bt <- betweenness(g, weights = 1 / E(g)$weight, normalized = TRUE)
  member_metrics[[ch]] <- tibble(bioguide = V(g)$name, chamber = ch,
                                 degree = degree(g), weighted_degree = strength(g),
                                 betweenness = bt, pagerank = page_rank(g, weights = E(g)$weight)$vector)
}
member_metrics <- bind_rows(member_metrics)

member_summary <- members %>%
  left_join(member_topic %>% pivot_wider(names_from = topic, values_from = c(bills_signed, bills_sponsored), values_fill = 0), by = "bioguide") %>%
  left_join(signers %>% count(bioguide, name = "topic_bills_signed_total"), by = "bioguide") %>%
  left_join(cross_party, by = "bioguide") %>%
  left_join(member_metrics, by = c("bioguide", "chamber")) %>%
  mutate(across(starts_with("bills_"), ~ replace_na(.x, 0L)),
         topic_bills_signed_total = replace_na(topic_bills_signed_total, 0L)) %>%
  arrange(chamber, desc(topic_bills_signed_total))
write_csv(member_summary, "output/member_summary.csv")

# Targeting list: the columns an advocacy director needs on Monday
targeting <- member_summary %>%
  transmute(chamber, full_name, party, state, district,
            maternal = bills_signed_maternal, deaf_hoh = bills_signed_deaf_hoh, disability = bills_signed_disability,
            total = topic_bills_signed_total,
            cross_party_share = round(cross_party_share, 2),
            bridge_score = round(betweenness, 3),
            instagram, x, instagram_url, x_url) %>%
  arrange(chamber, desc(total))
write_csv(targeting, "output/targeting_list.csv")

# Members who signed nothing in a topic, by chamber (the "sign nothing" list)
nothing <- member_summary %>%
  filter(topic_bills_signed_total == 0 | bills_signed_maternal == 0) %>%
  transmute(chamber, full_name, party, state, district, maternal = bills_signed_maternal, deaf_hoh = bills_signed_deaf_hoh, disability = bills_signed_disability)
write_csv(nothing, "output/members_with_no_maternal_bills.csv")

# ---- 3. Bill-to-bill coalition overlap ---------------------------
jaccard_pairs <- function(sig_topic) {
  sets <- split(sig_topic$bioguide, sig_topic$bill_id)
  ids <- names(sets)[lengths(sets) >= 5]
  if (length(ids) < 2) return(tibble())
  expand_grid(a = ids, b = ids) %>% filter(a < b) %>%
    mutate(jaccard = map2_dbl(a, b, ~ length(intersect(sets[[.x]], sets[[.y]])) / length(union(sets[[.x]], sets[[.y]])))) %>%
    arrange(desc(jaccard))
}
overlap <- bill_topics %>% distinct(topic, bill_id) %>%
  group_by(topic) %>% group_map(~ jaccard_pairs(signers %>% filter(bill_id %in% .x$bill_id)) %>% mutate(topic = .y$topic)) %>%
  bind_rows() %>%
  left_join(bills %>% select(a = bill_id, title_a = title), by = "a") %>%
  left_join(bills %>% select(b = bill_id, title_b = title), by = "b") %>%
  select(topic, a, title_a, b, title_b, jaccard)
write_csv(overlap, "output/bill_coalition_overlap.csv")

# ---- 4. Headline numbers -----------------------------------------
hl <- c(
  sprintf("Bills classified: %d (%s)", nrow(bills), paste(sprintf("%s %d", topics[names(table(unlist(str_split(bills$topics, '\\|'))))], table(unlist(str_split(bills$topics, "\\|")))), collapse = "; ")),
  sprintf("Members appearing as sponsor or cosponsor: %d (%d House, %d Senate)", nrow(members), sum(members$chamber == "House"), sum(members$chamber == "Senate")),
  sprintf("Signer rows (sponsor + cosponsor): %d", nrow(signers)),
  sprintf("Bipartisan bills (at least one D and one R signer): %d of %d (%s)", sum(bill_summary$bipartisan), nrow(bill_summary), percent(mean(bill_summary$bipartisan), 1)),
  sprintf("Bills with no cosponsors at all: %d", sum(bill_summary$signers <= 1)),
  sprintf("Abortion-policy bills tagged and set aside: %d", nrow(abortion_bills)),
  sprintf("Largest coalition: %s, %d signers", bill_summary$title[1], bill_summary$signers[1])
)
writeLines(hl, "output/headline_numbers.txt"); cat(paste(hl, collapse = "\n"), "\n")

# ---- 5. Figures --------------------------------------------------
theme_set(theme_minimal(base_size = 13) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot"))

# Fig 1: member network, House, maternal health bills
plot_network <- function(ch, topic_key, file, title) {
  ids <- bill_topics %>% filter(topic == topic_key, chamber == ch) %>% pull(bill_id)
  sig <- signers %>% filter(bill_id %in% ids)
  if (n_distinct(sig$bioguide) < 5) return(invisible(NULL))
  g <- project_members(sig)
  V(g)$nbills <- as.integer(table(sig$bioguide)[V(g)$name])
  # Draw only ties of two or more shared bills, so a single very large bill does not
  # collapse a whole party into one blob. Members with no such tie are dropped from the picture.
  g <- delete_edges(g, E(g)[weight < 2])
  g <- delete_vertices(g, degree(g) == 0)
  V(g)$party <- members$party[match(V(g)$name, members$bioguide)]
  V(g)$label <- str_remove(members$full_name[match(V(g)$name, members$bioguide)], "^(Rep\\.|Sen\\.|Del\\.|Rescom\\.) ") %>% str_remove(",.*$")
  set.seed(42)
  lay <- layout_with_fr(g, weights = sqrt(E(g)$weight), niter = 2000)
  png(file, width = 2000, height = 2000, res = 170)
  par(mar = c(1, 1, 3, 1))
  plot(g, layout = lay,
       vertex.size = 2 + sqrt(V(g)$nbills) * 2.2,
       vertex.color = adjustcolor(pal_party[V(g)$party], 0.85), vertex.frame.color = "white",
       vertex.label = ifelse(rank(-V(g)$nbills, ties.method = "first") <= 10, V(g)$label, NA),
       vertex.label.cex = 0.7, vertex.label.color = "black", vertex.label.family = "sans",
       edge.width = 0.2 + E(g)$weight / max(E(g)$weight) * 3, edge.color = adjustcolor("grey40", 0.25))
  title(main = title, cex.main = 1.2)
  mtext("Ties = two or more topic bills signed together; node size = bills signed; ten most active members labeled", side = 3, line = 0.2, cex = 0.8, col = "grey30")
  legend("bottomleft", legend = c("Democrat", "Republican", "Independent"), pch = 19, col = pal_party[c("D", "R", "I")], bty = "n")
  dev.off()
}
plot_network("House", "maternal", "figures/fig1_house_maternal_network.png", "House members who sign maternal health bills together, 119th Congress")
plot_network("Senate", "maternal", "figures/fig2_senate_maternal_network.png", "Senators who sign maternal health bills together, 119th Congress")
plot_network("House", "disability", "figures/fig3_house_disability_network.png", "House members who sign disability bills together, 119th Congress")

# Fig 4: the 25 biggest bills by signers, party split
fig4 <- bill_summary %>% slice_max(signers, n = 25, with_ties = FALSE) %>%
  mutate(title = str_trunc(title, 60), title = fct_reorder(title, signers)) %>%
  pivot_longer(c(dem, rep, ind), names_to = "party", values_to = "n") %>%
  mutate(party = factor(party, levels = c("dem", "ind", "rep"), labels = c("Democrat", "Independent", "Republican"))) %>%
  ggplot(aes(x = n, y = title, fill = party)) + geom_col() +
  scale_fill_manual(values = c(Democrat = "#2166ac", Independent = "#4d9221", Republican = "#b2182b"), name = NULL) +
  labs(title = "The 25 largest coalitions across the three topics", subtitle = "Sponsor plus cosponsors, 119th Congress", x = "Signers", y = NULL) +
  theme(legend.position = "top")
ggsave("figures/fig4_largest_coalitions.png", fig4, width = 11, height = 9, dpi = 150, bg = "white")

# Fig 5: bridges. Top 20 House members by betweenness in the all-topic projection
fig5 <- member_summary %>% filter(chamber == "House", !is.na(betweenness)) %>%
  slice_max(betweenness, n = 20, with_ties = FALSE) %>%
  mutate(label = str_remove(full_name, "^Rep\\. ") %>% str_replace(",\\s*", ", "), label = fct_reorder(label, betweenness)) %>%
  ggplot(aes(x = betweenness, y = label, color = party)) +
  geom_segment(aes(x = 0, xend = betweenness, yend = label), color = "grey75") + geom_point(size = 3.5) +
  scale_color_manual(values = pal_party, name = NULL) +
  labs(title = "House members who bridge the cosponsorship network", subtitle = "Normalized betweenness in the member projection across all three topics; high values sit between otherwise separate coalitions",
       x = "Betweenness", y = NULL) + theme(legend.position = "top", axis.text.y = element_text(size = 9))
ggsave("figures/fig5_house_bridges.png", fig5, width = 10, height = 8, dpi = 150, bg = "white")

# Fig 6: cross-party share vs number of bills signed, House
fig6 <- member_summary %>% filter(chamber == "House", topic_bills_signed_total > 0, party %in% c("D", "R")) %>%
  ggplot(aes(x = topic_bills_signed_total, y = cross_party_share, color = party)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = pal_party, name = NULL) +
  scale_y_continuous(labels = percent_format(1)) +
  labs(title = "Volume versus reach across the aisle, House", subtitle = "Each point is a member: how many of the 200-odd topic bills they signed, and what share of their fellow signers came from the other party",
       x = "Topic bills signed", y = "Share of co-signers from the other party") + theme(legend.position = "top")
ggsave("figures/fig6_house_volume_vs_crossparty.png", fig6, width = 10, height = 7, dpi = 150, bg = "white")

# ---- 6. Graph JSON for docs/index.html ---------------------------
edges_all <- list()
for (ch in c("House", "Senate")) {
  for (tk in names(topics)) {
    ids <- bill_topics %>% filter(topic == tk, chamber == ch) %>% pull(bill_id)
    sig <- signers %>% filter(bill_id %in% ids)
    if (n_distinct(sig$bioguide) < 3) next
    g <- project_members(sig)
    el <- as_data_frame(g, what = "edges") %>% mutate(chamber = ch, topic = tk)
    edges_all[[paste(ch, tk)]] <- el
  }
}
edges_all <- bind_rows(edges_all) %>% filter(weight >= 1)
nodes_json <- member_summary %>% filter(topic_bills_signed_total > 0) %>%
  transmute(id = bioguide, name = str_remove(full_name, "\\s*\\[.*\\]$"), party, state, district = replace_na(district, ""), chamber,
            maternal = bills_signed_maternal, deaf_hoh = bills_signed_deaf_hoh, disability = bills_signed_disability,
            total = topic_bills_signed_total, cross = round(replace_na(cross_party_share, 0), 2), instagram, x)
write_json(list(nodes = nodes_json, edges = edges_all %>% select(source = from, target = to, weight, chamber, topic),
                bills = bill_summary %>% select(bill_id, title, chamber, topics, signers, dem, rep, bipartisan, url)),
           "docs/graph.json", auto_unbox = TRUE, pretty = FALSE)

# README tables
md_table <- function(df) {
  hdr <- paste0("| ", paste(names(df), collapse = " | "), " |"); sep <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
  paste(c(hdr, sep, apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))), collapse = "\n")
}
t1 <- topic_summary %>% transmute(Topic = topic, Bills = bills, House = house_bills, Senate = senate_bills, `Median signers` = median_signers, `Bipartisan` = paste0(bipartisan_bills, " (", pct_bipartisan, ")"), `D sponsored` = dem_sponsored, `R sponsored` = rep_sponsored)
t2 <- bill_summary %>% slice_max(signers, n = 12, with_ties = FALSE) %>% transmute(Bill = bill_id, Title = str_trunc(title, 70), Signers = signers, D = dem, R = rep, Topics = topics)
t3 <- member_summary %>% filter(chamber == "House") %>% slice_max(topic_bills_signed_total, n = 12, with_ties = FALSE) %>% transmute(Member = full_name, Maternal = bills_signed_maternal, `Deaf/HoH` = bills_signed_deaf_hoh, Disability = bills_signed_disability, Total = topic_bills_signed_total, `Cross-party share` = percent(cross_party_share, 1))
t4 <- member_summary %>% filter(chamber == "Senate") %>% slice_max(topic_bills_signed_total, n = 12, with_ties = FALSE) %>% transmute(Member = full_name, Maternal = bills_signed_maternal, `Deaf/HoH` = bills_signed_deaf_hoh, Disability = bills_signed_disability, Total = topic_bills_signed_total, `Cross-party share` = percent(cross_party_share, 1))
t5 <- member_summary %>% filter(chamber == "House", !is.na(betweenness)) %>% slice_max(betweenness, n = 10, with_ties = FALSE) %>% transmute(Member = full_name, `Bills signed` = topic_bills_signed_total, `Cross-party share` = percent(cross_party_share, 1), Betweenness = round(betweenness, 3))
t6 <- overlap %>% filter(topic == "maternal") %>% slice_max(jaccard, n = 10, with_ties = FALSE) %>% transmute(`Bill A` = paste0(a, " ", str_trunc(title_a, 45)), `Bill B` = paste0(b, " ", str_trunc(title_b, 45)), `Shared signers (Jaccard)` = percent(jaccard, 1))
writeLines(c("## Topics", md_table(t1), "", "## Largest coalitions", md_table(t2), "", "## House members who sign the most", md_table(t3), "", "## Senators who sign the most", md_table(t4), "", "## House bridges", md_table(t5), "", "## Maternal health bills that share a coalition", md_table(t6)), "output/readme_tables.md")
message("Done.")

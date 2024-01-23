# read in the data, add the columns we want and burn to mergin for processing


# 1. change this to the correct project name in our GIS folder and delete this comment
dir_project <- 'sern_peace_fwcp_2023'


# read in the crossings data for the study area.  Use our naming convention of calling the object bcfishpass so
# we don't need to worry about breaking standardized code


# 2. use the newly updated extract-pg.R template script to see how to read in the crossings data from the database


# 3.  Read in the pscis assessments layer from the database.  Use our naming convention of calling the object pscis
# modify this query (and use the fpr_db_query function to do this using `ST_Intersects`
# https://github.com/NewGraphEnvironment/fish_passage_peace_2022_reporting/blob/7ec363e88d8034ffeaa577092ec0731438ffaee0/scripts/02_reporting/0160-load-bcfishpass-data.R#L133C1-L140C39



# 3. make a sqlite database named bcfishpass.sqlite and burn in the table naming it bcfishpass
# https://github.com/NewGraphEnvironment/fish_passage_peace_2022_reporting/blob/7ec363e88d8034ffeaa577092ec0731438ffaee0/scripts/02_reporting/0160-load-bcfishpass-data.R#L180




# 4 This stuff below is the old code from planning from the peace last year.  I will put ### hashmarks on new comments
# about how to customize it now that we are in the future in a different region.

conn <- readwritesqlite::rws_connect("data/bcfishpass.sqlite")
readwritesqlite::rws_list_tables(conn)
planning_raw <- readwritesqlite::rws_read_table("bcfishpass", conn = conn)
pscis_raw <- readwritesqlite::rws_read_table("pscis", conn = conn) %>%
  sf::st_drop_geometry()

### this ise that the data is in the right projectionevant below but may not be necesary anymore. you will see why
unique(planning_raw$utm_zone)


### If you can - and its helpful perhaps break out litle bits of this big MULTIPLE join
### join and run them a move at a time to see what is going on
planning <- left_join(

  ### have a look at the new function fpr_sp_assign_sf_from_utm to see another way to do this because if the data
  ### is in more than one utm zone the way this is written will  not work. Give it a try
  planning_raw %>%
    st_as_sf(coords = c('utm_easting', 'utm_northing'), crs = 26910, remove = F) %>%
    st_transform(crs = 3005),

  ### another join
  planning_raw2 <- left_join(
    planning_raw %>%
      arrange(aggregated_crossings_id) ,

    pscis_raw %>%
      mutate(stream_crossing_id = as.character(stream_crossing_id)) %>%
      dplyr::select(
        stream_crossing_id,
        stream_name,
        road_name,
        outlet_drop,
        downstream_channel_width,
        habitat_value_code,
        image_view_url),

    by = c('aggregated_crossings_id' = 'stream_crossing_id')) %>%
    filter(is.na(pscis_status) | (pscis_status != 'HABITAT CONFIRMATION' &
                                    barrier_status != 'PASSABLE' &
                                    barrier_status != 'UNKNOWN')) %>%
    ### since we are deep in salmon country here lets use a coho metric.  Lets change this to look at everything with
    ### over 1km of rearing habitat to start. Don't forget about fpr_dbq_lscols .  Also - if not familiar have a look at
    ###  our tables in methods of past reports (Skeena has salmon) which explain the thresholds in general. Look at the
    ### csv in bcfishpass that decided what they are too though because they are new!
    filter(bt_rearing_km > 0.3) %>%
    filter(crossing_type_code != 'OBS') %>%
    filter(is.na(barriers_anthropogenic_dnstr)) %>%
    ### this will not work because we have no pdf maps for this area.
    ### Can be useful (mostly for other collaborators) when we do. can nuke
    mutate(map_link = paste0('https://hillcrestgeo.ca/outgoing/fishpassage/projects/parsnip/archive/2022-05-27/FishPassage_', dbm_mof_50k_grid, '.pdf')) %>%

    ### make a note that this is the column that you will use to in the mergin project to query in the "Query Builder"
    ### so that you filter to only see the ones that you tagged as "my_review" = TRUE. Do a bit of homework to see how
    ### to see how to use the `Query Builder`.  Note also that you can add a query that will make it so that you only
    ###see the ones that you have not yet reviewed. I will leave it to you to try to do that. Can help of course if need be
    mutate(my_review = TRUE) %>%
    dplyr::select(aggregated_crossings_id,
                  my_review,
                  stream_name,
                  road_name,
                  outlet_drop,
                  downstream_channel_width,
                  habitat_value_code,
                  image_view_url),

  by = 'aggregated_crossings_id'

) %>%
  mutate(
    my_priority = NA_character_,
    my_priority_comments = NA_character_,
    my_citation_key1 = NA_character_,
    my_citation_key2 = NA_character_,
    my_citation_key3 = NA_character_
  )

### this is going to write it into the mergin project.
### open it in QGIS and view the file.  Have a look at the Peace project to see where we put it.
planning %>%
  sf::st_write(paste0('../../gis/',
                      dir_project,
                      '/',


                      ### let's change this so it gives us a version number that we specify at the header of this file
                      paste0('planning_', format(lubridate::now(), "%Y%m%d")),



                      '.gpkg'),
               # turned this T now that we have time in name
               delete_layer = T)






































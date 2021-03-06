#function to perform bulk upload of documents to DocumentCloud
#returns a df of paths and destination urls
#NOTE: must already be authenticated
#TODO: Add a lap time
#usage
#upload_documents(file_names, 208620, unlist(auth_response$refresh))
upload_documents <- function(path_list, project_id, refresh_token){
  #set the timer and report out
  start_time <- proc.time()[[3]]
  cat('...BEGINNING UPLOAD AT', toupper(format(Sys.time(), '%B %d, %Y %X %p')), '\n')

  #authenticate
  refresh_auth <- dc_refresh_token(refresh_token)
  bearer <- paste("Bearer", unlist( refresh_auth$access ) )

  #format paths for post request
  documents <- list(title = path_list, src = path_list) %>%
    as_tibble() %>%
    mutate(title = sub('.*/', '', title)) %>%
    mutate(projects = list(c(project_id, project_id)))
  #check for valid filetypes
  documents$valid_filetype <- check_filetype(documents$src)
  #clean up titles and if filetype isn't valid, change to NA
  documents <- documents %>%
    mutate(title = ifelse(title != valid_filetype,
                          str_replace(title, valid_filetype, ''),
                          NA
    )
    )
  #check for duplicates
  documents <- documents %>%
    filter(!is.na(title)) %>%
    dupe_check('title')

  #initialize our url list
  url_list <- tibble(id = character(), canonical_url = character())

  #debug
  #print(documents)

  #get the document count and set other variables
  doc_count <- documents %>% nrow()
  chunk_size <- 25
  batches <- ceiling(doc_count/chunk_size)
  current_batch <- 1

  cat('...PREPARING', doc_count, 'VALID DOCUMENTS FOR UPLOAD\n')

  documents_split <- documents %>%
    split(rep(1:batches, each=chunk_size)[1:doc_count])

  while(current_batch <= batches){
    cat('...UPLOADING BATCH', current_batch, 'OF', batches, 'BATCHES\n')

    document_batch <- documents_split[[current_batch]]

    post_success <- FALSE
    while(post_success == FALSE){
      bulk_post_response <- POST('https://api.www.documentcloud.org/api/documents/',
                                 add_headers('Authorization' = bearer),
                                 body = document_batch,
                                 encode = 'json')
      #check status code
      if(bulk_post_response$status_code == 201){
        cat('...POST SUCCESSFUL\n')
        post_success <- TRUE
      }
      else if(bulk_post_response$status_code == 403){
        #authenticate
        refresh_auth <- dc_refresh_token(refresh_token)
        bearer <- paste("Bearer", unlist( refresh_auth$access ) )
      }
      else{
        cat('✗  ERROR:', bulk_post_response$status_code, '- EXITING AFTER', proc.time()[[3]] - start_time, 'SECONDS\n')
        return(bulk_post_response)
      }
    }

    #debug
    #print(content(bulk_post_response))

    #convert an unnamed nested list of lists into a tidy dataframe
    #then join to documents_file
    posted_documents <- transpose(content(bulk_post_response)) %>%
      map_dfc(unlist) %>%
      left_join(
        documents, by = c('title')
      )

    #debug
    #print(posted_documents)

    #process the put request
    put_success <- FALSE
    while(put_success == FALSE){
      bulk_put_response <- mapply(
        bulk_put_request,
        posted_documents$presigned_url,
        posted_documents$src
      )

      #debug
      #View(bulk_put_response)

      #check for status code 200
      bulk_put_response_list <- bulk_put_response[2,] %>%
        as_tibble() %>%
        pivot_longer(cols = starts_with('https:'), names_to = 'presigned_url', values_to = 'status_code')

      success_puts <- bulk_put_response_list %>%
        filter(status_code == 200) %>%
        nrow()
      total_puts <- bulk_put_response_list %>% nrow()

      #fix this onn fail
      if(success_puts == total_puts){
        cat('...ALL', success_puts, 'PUTS SUCCESSFUL\n')
        put_success <- TRUE
      }
      #need to add some reporting here
      else{
        cat('✗  ', success_puts, 'OUT OF', total_puts, 'PUTS SUCCESSFUL\n')
        put_success <- TRUE
      }
    }

    #processing request
    process_success <- FALSE
    while(process_success == FALSE){
      bulk_process_response <- POST(
        add_headers('Authorization' = bearer),
        url = paste0('https://api.www.documentcloud.org/api/documents/process/'),
        body = posted_documents %>% select(id),
        encode = 'json'
      )

      #check status code
      if(bulk_process_response$status_code == 200){
        cat('...PROCESS REQUESTS SUCCESSFUL\n')
        process_success <- TRUE
      }
      else if(bulk_process_response$status_code == 403){
        #authenticate
        refresh_auth <- dc_refresh_token(refresh_token)
        bearer <- paste("Bearer", unlist( refresh_auth$access ) )
      }
      else{
        cat('✗  PROCESSING ERROR:', bulk_post_response$status_code, '- EXITING AFTER', proc.time()[[3]] - start_time, 'SECONDS\n')
        #return(bulk_post_response)
        break
      }
    }

    #debug
    #print(bulk_process_response)

    url_list <- url_list %>%
      rbind(
        posted_documents %>%
          select(id, canonical_url)
      )

    cat('✓  FINISHED BATCH', current_batch, 'AFTER', proc.time()[[3]] - start_time, 'SECONDS\n')

    current_batch <- current_batch + 1
  }

  cat('✓  BULK UPLOAD COMPLETE AFTER', proc.time()[[3]] - start_time, 'SECONDS\n')

  return(url_list)

}

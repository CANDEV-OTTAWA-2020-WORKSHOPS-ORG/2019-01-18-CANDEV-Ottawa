
getFeatures <- function(
    input_matrix  = NULL,
    col_id        = NULL,
    col_text      = NULL,
    file_features = NULL
    ) {

    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat("\ngetFeatures() starts.\n");

    require(text2vec);
    require(stopwords);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( is.null(input_matrix) ) { return(NULL); }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(file_features) ) {

        cat(paste0("\n### ",file_features," already exists; loading this file ...\n"));

        list.features <- readRDS(file = file_features);

        cat(paste0("\n### Finished loading text statistics.\n"));

    } else {

        tokens <- input_matrix[,col_text] %>%
            tolower() %>%
            word_tokenizer();

        tokens_iterator <- itoken(
            iterable    = tokens,
            ids         = input_matrix[,col_id],
            progressbar = FALSE
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my_stopwords <- stopwords(language = "en", source = "smart");

        tokens_vocabulary <- create_vocabulary(
            it        = tokens_iterator,
            stopwords = my_stopwords
            );

        tokens_vocabulary <- prune_vocabulary(
            vocabulary     = tokens_vocabulary,
            term_count_min = 5L
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        my_vectorizer <- vocab_vectorizer(vocabulary = tokens_vocabulary);

        document_term_matrix <- create_dtm(
            it         = tokens_iterator,
            vectorizer = my_vectorizer
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        list.features <- list(
            token_iterator       = tokens_iterator,
            vocabulary           = tokens_vocabulary,
            document_term_matrix = document_term_matrix
            );

        if (!is.null(file_features)) {
            saveRDS(object = list.features, file = file_features);
            }

        rm(tokens_iterator,tokens_vocabulary,document_term_matrix);

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\ngetFeatures() quits.");
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.features );

    }

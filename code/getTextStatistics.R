
getTextStatistics <- function(
    DF.input = NULL,
    col.id   = NULL,
    col.text = NULL,
    file_text_statistics = NULL
    ) {

    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat("\ngetTextStatistics() starts.\n");

    require(text2vec);
    require(stopwords);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( is.null(DF.input) ) { return(NULL); }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(file_text_statistics) ) {

        cat(paste0("\n### ",file_text_statistics," already exists; loading this file ...\n"));

        load(file = file_text_statistics);

        cat(paste0("\n### Finished loading text statistics.\n"));

        }
    else {

        tokens <- DF.input[,col.text] %>%
            tolower() %>%
            word_tokenizer();

        tokens_iterator <- itoken(
            iterable    = tokens,
            ids         = DF.input[,col.id],
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

        tfidf_instance <- TfIdf$new();
        tfidf_matrix   <- fit_transform(
            x     = document_term_matrix,
            model = tfidf_instance
            );

        term_cooccurence_matrix <- create_tcm(
            it                = tokens_iterator,
            vectorizer        = my_vectorizer,
            skip_grams_window = 5L
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        text.statistics <- list(
            token_iterator          = tokens_iterator,
            vocabulary              = tokens_vocabulary,
            document_term_matrix    = document_term_matrix,
            tfidf_matrix            = tfidf_matrix,
            term_cooccurence_matrix = term_cooccurence_matrix
            );

        if (!is.null(file_text_statistics)) {
            save(file = file_text_statistics, text.statistics);
            }

        rm(tokens_iterator,tokens_vocabulary,document_term_matrix,tfidf_matrix,term_cooccurence_matrix);

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\ngetTextStatistics() quits.");
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( text.statistics );

    }

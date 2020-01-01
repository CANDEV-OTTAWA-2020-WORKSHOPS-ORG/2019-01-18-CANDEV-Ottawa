
doLDA <- function(
    input_matrix     = NULL,
    file_output      = NULL,
    DF.raw           = NULL,
    n_topics         = 10,
    n_iter           = 20,
    n_top_words      = 20,
    lambda_top_words = 0.2,
    heatmap_palette  = grDevices::colorRampPalette(c(
		"black",
		"black","black","black","gray13","gray25","gray38",
		"gray50",
		"red","orange","yellow","white","white","white",
		"white"
		))(n=200)
    ) {

    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat("\ndoLDA() starts.\n");

    require(ggplot2)
    require(gplots);
    require(text2vec);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( is.null(input_matrix) ) { return(NULL); }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if (file.exists(file_output)) {

        cat(paste0("\n# ",file_output," already exists; loading this file ...\n"));

        my.LDA <- readRDS(file = file_output);

        cat(paste0("\n# Finished loading trained Latent Dirichlet Allocation model.\n"));

    } else {

        cat(paste0("\n# ",file_output," not found; start fitting Latent Dirichlet Allocation model ...\n"));

        my.LDA <- LatentDirichletAllocation$new(
            n_topics         = n_topics,
            doc_topic_prior  = 50 / n_topics,
            topic_word_prior =  1 / n_topics
            );

        my.LDA$fit_transform(
            x                   = input_matrix,
            n_iter              = n_iter,
            convergence_tol     = -0.9999, # -1
            n_check_convergence = 1,       #  default value of 0 causes an error
            progressbar         = interactive()
            );

        saveRDS(object = my.LDA, file = file_output);

        cat(paste0("\n# Latent Dirichlet Allocation training complete; trained model saved to file.\n"));

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    doLDA_saveTopicStatistics(
        my.LDA           = my.LDA,
        n_top_words      = n_top_words,
        lambda_top_words = lambda_top_words
        );

    DF.documentTopicDistributon <- doLDA_getDocumentTopicDistribution(
        my.LDA       = my.LDA,
        input_matrix = input_matrix,
        DF.raw       = DF.raw,
        n_iter       = n_iter
        );

    doLDA_plotCorrHeatmap(
        DF.input        = DF.documentTopicDistributon,
        heatmap_palette = heatmap_palette
        );

    doLDA_plotEntropy(
        DF.input = DF.documentTopicDistributon
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\ndoLDA() quits.");
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( my.LDA );

    }

##############################
doLDA_saveTopicStatistics <- function(
    my.LDA                 = NULL,
    n_top_words            = NULL,
    lambda_top_words       = NULL,
    CSV.top.words          = "lda-topic-top-words.csv",
    CSV.word.distributions = "lda-topic-word-distributions.csv"
    ) {

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.temp <- my.LDA$get_top_words(n = n_top_words, lambda = lambda_top_words);
    colnames(DF.temp) <- paste0("Topic",seq(1,ncol(DF.temp)));
    write.csv(
        file = CSV.top.words,
        x    = DF.temp
        );
    
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.temp <- data.frame(t(my.LDA$topic_word_distribution));
    colnames(DF.temp) <- paste0("Topic",seq(1,ncol(DF.temp),1));
    
    DF.temp[,"word"] <- rownames(DF.temp);
    DF.temp <- DF.temp[,c("word",setdiff(colnames(DF.temp),"word"))];
    
    write.csv(
        file      = CSV.word.distributions,
        x         = DF.temp,
        row.names = FALSE
        );
    
    return( NULL );
    
    }

doLDA_plotCorrHeatmap <- function(
    DF.input              = NULL,
    heatmap_palette       = NULL,
    CSV.corr              = "lda-correlations.csv",
    PNG.corr              = "lda-correlations-all.png",
    PNG.corr.topic        = "lda-correlations-topic.png",
    PNG.corr.topic.domain = "lda-correlations-topic-domain.png"
    ) {

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    temp.colnames <- setdiff(colnames(DF.input),c("document","domain","entropy","two_entropy"));
    results.cor <- cor(
        x = as.matrix(DF.input[,temp.colnames])
        );
    
    write.csv(
        file = CSV.corr,
        x    = results.cor
        );

    if (!is.null(heatmap_palette)) {
        png(filename = PNG.corr, height = 12, width = 12, units = "in", res = 300);
        heatmap.2(
            x          = as.matrix(results.cor),
            dendrogram = "both",
            trace      = "none",
            labRow     = NULL,
            key.xlab   = NULL,
            key.ylab   = NULL,
            col        = heatmap_palette
        );
        dev.off();
        }

    if (!is.null(heatmap_palette)) {
        names.topic <- grep(x = colnames(results.cor), pattern = "Topic", value = TRUE);
        DF.temp     <- results.cor[names.topic,names.topic];
        png(filename = PNG.corr.topic, height = 12, width = 12, units = "in", res = 300);
        heatmap.2(
            x          = as.matrix(DF.temp),
            dendrogram = "both",
            trace      = "none",
            labRow     = NULL,
            key.xlab   = NULL,
            key.ylab   = NULL,
            col        = heatmap_palette
            );
        dev.off();
        }
    
    
    if (!is.null(heatmap_palette)) {

        names.domain <- grep(x = colnames(results.cor), pattern = "domain", value = TRUE);
        names.topic  <- grep(x = colnames(results.cor), pattern = "Topic",  value = TRUE);

        DF.temp      <- results.cor[names.topic,names.domain];
        colnames(DF.temp) <- gsub(
            x           = colnames(DF.temp),
            pattern     = "domain",
            replacement = ""
            );

        png(filename = PNG.corr.topic.domain, height = 12, width = 12, units = "in", res = 300);
        heatmap.2(
            x          = as.matrix(DF.temp),
            dendrogram = "row",
            trace      = "none",
            labRow     = NULL,
            key.xlab   = NULL,
            key.ylab   = NULL,
            col        = heatmap_palette
            );
        dev.off();
        }

    return( NULL );
    
    }
    
doLDA_plotEntropy <- function(
    DF.input    = NULL,
    FILE.ggplot = "lda-document-entropy.png"
    ) {
        
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    textsize.title <- 40;
    textsize.axis  <- 20;
    
    my.ggplot <- ggplot(data = NULL) + theme_bw();
    my.ggplot <- my.ggplot + theme(
        title             = element_text(size = textsize.title, face = "bold"),
        axis.title.x      = element_blank(),
        axis.title.y      = element_blank(),
        axis.text.x       = element_text(size = textsize.axis,  face = "bold"),
        axis.text.y       = element_text(size = textsize.axis,  face = "bold"),
        panel.grid.major  = element_line(colour="gray", linetype=2, size=0.25),
        panel.grid.minor  = element_line(colour="gray", linetype=2, size=0.25),
        legend.position   = c(0.25,0.85),
        legend.title      = element_blank(),
        legend.direction  = "vertical", # "horizontal",
        legend.key.size   = unit(1,"cm"),
        legend.key        = element_rect(fill=alpha('white',0)),
        legend.text       = element_text(size=25,face = "bold"),
        legend.background = element_rect(fill=alpha('white',0))
        );
    
    my.ggplot <- my.ggplot + geom_hline(yintercept = 0,colour="gray",size=0.75);
    my.ggplot <- my.ggplot + geom_vline(xintercept = 0,colour="gray",size=0.75);
    
    max.entropy <- ceiling(1.1 * max(DF.input[,"two_entropy"]));
    my.ggplot <- my.ggplot + scale_x_continuous(
        limits = c(0,max.entropy),
        breaks = seq(0,max.entropy,round(max.entropy/10,digits=0))
        );
    
    #my.ggplot <- my.ggplot + geom_histogram(
    #    data    = DF.input,
    #    mapping = aes(
    #        x    = tempvar,
    #        fill = estimateType
    #        ),
    #    alpha = 0.2
    #    );
    
    my.ggplot <- my.ggplot + geom_density(
        data    = DF.input,
        mapping = aes(x = two_entropy),
        alpha   = 0.2
        );
    
    ggsave(file = FILE.ggplot, plot = my.ggplot, dpi = 300, height = 4, width = 8, units = 'in');

    return( NULL );
    
    }

doLDA_getDocumentTopicDistribution <- function(
    my.LDA       = NULL,
    input_matrix = NULL,
    DF.raw       = NULL,
    n_iter       = NULL,
    FILE.output  = "lda-document-topic-distributions.csv"
    ) {
    
    DF.temp <- my.LDA$transform(
        x                   = input_matrix,
        n_iter              = n_iter,
        convergence_tol     = -0.9999, # -1
        n_check_convergence = 1,       #  default value of 0 causes an error
        progressbar         = FALSE
        );
    DF.temp <- as.data.frame(DF.temp);
    colnames(DF.temp) <- paste0("Topic",seq(1,ncol(DF.temp),1));
    
    DF.temp[,"entropy"] <- apply(
        X      = DF.temp,
        MARGIN = 1,
        FUN    = function(x) {
            log2_x <- sapply(x, FUN = function(z) { ifelse(0==z,0,log2(z)) } );
            return( - sum(x*log2_x) );
            }        
        );
    
    DF.temp[,"two_entropy"] <- 2 ^ DF.temp[,"entropy"];
    
    DF.temp[,"document"] <- rownames(input_matrix);
    
    DF.temp <- dplyr::left_join(
        x  = DF.temp,
        y  = DF.raw[,c("id","domain")],
        by = c("document" = "id")
        );
    
    DF.temp <- as.data.frame(DF.temp);
    DF.temp[,"domain"] <- as.factor(DF.temp[,"domain"]);
    
    colnames.leftmost <- c("document","domain","entropy","two_entropy");
    DF.temp <- DF.temp[,c(colnames.leftmost,setdiff(colnames(DF.temp),colnames.leftmost))];
    
    DF.temp <- cbind(
        DF.temp,
        as.data.frame(model.matrix(~ -1 + domain, data = DF.temp))
        );
    
    write.csv(
        file      = FILE.output,
        x         = DF.temp,
        row.names = FALSE
        );
    
    return( DF.temp );

    }

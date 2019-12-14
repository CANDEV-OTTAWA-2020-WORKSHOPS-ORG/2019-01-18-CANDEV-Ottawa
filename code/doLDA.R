
doLDA <- function(
    input_matrix     = NULL,
    file_output      = NULL,
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

        readRDS(file = file_output);

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

    cat("\n# str(my.LDA):\n");
    print(   str(my.LDA)    );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
	DF.temp <- my.LDA$get_top_words(n = n_top_words, lambda = lambda_top_words);
	colnames(DF.temp) <- paste0("Topic",seq(1,ncol(DF.temp)));
	write.csv(
		file = "lda-top-words.csv",
		x    = DF.temp
		);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.temp <- data.frame(t(my.LDA$topic_word_distribution));
    colnames(DF.temp) <- paste0("Topic",seq(1,ncol(DF.temp),1));

    DF.temp[,"word"] <- rownames(DF.temp);
    DF.temp <- DF.temp[,c("word",setdiff(colnames(DF.temp),"word"))];

	write.csv(
		file      = "lda-topic-word-distributions.csv",
		x         = DF.temp,
		row.names = FALSE
		);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
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
    DF.temp <- DF.temp[,c("document","entropy","two_entropy",setdiff(colnames(DF.temp),c("document","entropy","two_entropy")))];

	write.csv(
		file      = "lda-document-topic-distributions.csv",
		x         = DF.temp,
		row.names = FALSE
		);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    results.cor <- cor(
    	x = as.matrix(DF.temp[,setdiff(colnames(DF.temp),c("document","entropy","two_entropy"))])
    	);

	write.csv(
		file = "lda-document-topic-distributions-cor.csv",
		x    = results.cor
		);

	if (!is.null(heatmap_palette)) {
		png(filename = "lda-document-topic-distributions-cor.png", height = 12, width = 12, units = "in", res = 300);
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

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    FILE.ggplot <- "lda-document-entropy.png";

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

    max.entropy <- ceiling(1.1 * max(DF.temp[,"two_entropy"]));
    my.ggplot <- my.ggplot + scale_x_continuous(
        limits = c(0,max.entropy),
        breaks = seq(0,max.entropy,round(max.entropy/10,digits=0))
        );

    #my.ggplot <- my.ggplot + geom_histogram(
    #    data    = DF.temp,
    #    mapping = aes(
    #        x    = tempvar,
    #        fill = estimateType
    #        ),
    #    alpha = 0.2
    #    );

    my.ggplot <- my.ggplot + geom_density(
        data    = DF.temp,
        mapping = aes(x = two_entropy),
        alpha   = 0.2
        );

    ggsave(file = FILE.ggplot, plot = my.ggplot, dpi = 300, height = 4, width = 8, units = 'in');

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\ndoLDA() quits.");
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( my.LDA );

    }

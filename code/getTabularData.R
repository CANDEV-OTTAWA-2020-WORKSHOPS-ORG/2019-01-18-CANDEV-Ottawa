
getTabularData <- function(
    raw_data_folder = NULL,
    file_prefix     = NULL,
    output_file     = NULL
    ) {

    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat("\ngetTabularData() starts.\n");

    require(xml2);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( !file.exists(raw_data_folder) ) { return(NULL); }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(output_file) ) {

        cat(paste0("\n### ",output_file," already exists; loading this file ...\n"));

        DF.raw <- readRDS(file = output_file);

        cat(paste0("\n### Finished loading raw data.\n"));

    } else {

        templist <- list();
        for (tempXML in list.files(path=raw_data_folder,pattern=file_prefix)) {

            tempCSV <- gsub(x=tempXML,pattern="\\.txt",replacement='.csv');
            print( paste0( tempXML , "; ", tempCSV ) );

            templist[[tempXML]] <- xml2csv(
                 inputXML = file.path(raw_data_folder,tempXML),
                outputCSV = tempCSV
                );
            }

        DF.raw <- templist[[1]];
        for (i in seq(2,length(templist))) {
            DF.raw <- rbind(DF.raw,templist[[i]])
            }

        if (!is.null(output_file)) {
            saveRDS(object = DF.raw, file = output_file);
            }

        rm(templist);

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\ngetTabularData() quits.");
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.raw );

    }

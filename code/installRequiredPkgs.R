
installRequiredPkgs <- function(
    temp.RLib     = "RLib",
    packages.Bioc = c("ComplexHeatmap"),
    packages.CRAN = c("ggplot2","gplots","text2vec","xml2","stopwords","dplyr","tidyr")
    ) {

    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat("\ninstallRequiredPkgs.R() starts.\n");

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # create directory for temporary R library if not yet exists
    if ( !dir.exists(temp.RLib) ) { dir.create( temp.RLib ); }

    # append temporary library to R library paths
    .libPaths(c(.libPaths(),temp.RLib))

    cat("\n# temporary R library\n");
    print( temp.RLib );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # determine required but not-yet-installed R packages

    packages.to.be.installed.Bioc <- setdiff(
        packages.Bioc,
        installed.packages()[,"Package"]
        );
    
    cat("\n# packages.to.be.installed.Bioc\n");
    print(   packages.to.be.installed.Bioc   );
    
    packages.to.be.installed.CRAN <- setdiff(
        packages.CRAN,
        installed.packages()[,"Package"]
        );
    
    cat("\n# packages.to.be.installed.CRAN\n");
    print(   packages.to.be.installed.CRAN   );
    
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( max(length(packages.to.be.installed.Bioc),length(packages.to.be.installed.CRAN)) > 0 ) {

        # get URL of an active CRAN mirror
        CRANmirrors   <- getCRANmirrors();
        CRANmirrors   <- CRANmirrors[CRANmirrors[,"OK"]==1,];
        caCRANmirrors <- CRANmirrors[CRANmirrors[,"CountryCode"]=="ca",c("Name","CountryCode","OK","URL")];

        if (nrow(caCRANmirrors) > 0) {
            myRepoURL <- caCRANmirrors[nrow(caCRANmirrors),"URL"];
        } else if (nrow(CRANmirrors) > 0) {
            myRepoURL <- CRANmirrors[1,"URL"];
        } else {
            cat("\nERROR: Unable to find CRAN mirrors ...\n");
            quit(save = "no");
        }

        cat(paste0("\n# myRepoURL = ",myRepoURL,"\n"));

        if ( length(packages.to.be.installed.Bioc) > 0 ) {
            cat("\n##### installation of BiocManager starts ...\n");
            install.packages(
                pkgs         = c("BiocManager"),
                lib          = temp.RLib,
                repos        = myRepoURL,
                dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
                );
            cat("\n##### installation of BiocManager complete ...\n");
            library(package = "BiocManager", character.only = TRUE, lib.loc = temp.RLib);
            cat("\n##### installation of Bioconductor packages starts ...\n");
            BiocManager::install(
                pkgs         = packages.to.be.installed.Bioc,
                lib          = temp.RLib,
                dependencies = TRUE
                );
            cat("\n##### installation of Bioconductor packages complete ...\n");
            }

        if ( length(packages.to.be.installed.CRAN) > 0 ) {
            cat("\n# installation of packages starts ...\n");
            # install required but not-yet-installed R packages to temporary R library
            install.packages(
                pkgs         = packages.to.be.installed.CRAN,
                lib          = temp.RLib,
                repos        = myRepoURL,
                dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
                );
            cat("\n# installation of packages completed ...\n");
            }
        
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\ninstallRequiredPkgs.R() quits.");
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

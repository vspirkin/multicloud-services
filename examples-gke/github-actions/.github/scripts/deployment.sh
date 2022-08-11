# This code is part of workflow

# FOR EVERY HELM CHART ############################################################
# ℹ️ Notice: in application folder we should have subfolder with following naming: 
#      [0-9][0-9]_chart_<chart-name> 
# where: 
#  - digits define the instalation order
#  - chart-name is name of chart to be installed
# The chart-name will be used in command:
#     helm install release-name helm-repo/chart-name
# ##################################################################################
for DIR_CH in [0-9][0-9]_chart_*$CHART_NAME*/; do
    
    CHART=$([[ -d "$DIR_CH" ]] && echo $DIR_CH | sed 's/[0-9][0-9]_chart_//' | sed 's/\///')
    
    DIR_CH=$(echo $DIR_CH | sed 's/\///')
    
    # evaluate ENV variables
    envsubst < $DIR_CH/override_values.yaml > overrides.yaml

    # 🖊️ (Optional) EDIT 1st line of chart.ver file with chart version number
    VER=$(head -n 1 $DIR_CH/chart.ver)
    
    FLAGS="helm_repo/$CHART --install --version=$VER -n $NS -f $(pwd)/overrides.yaml"
    
    case $COMMAND in

    install)
        echo "Installing..."
        CMD="upgrade"
        ;;

    uninstall)
        echo "Uninstalling..."
        CMD="uninstall"
        FLAGS=""
        ;;

    validate)
        echo "Validating..."
        CMD="upgrade"
        FLAGS+=" --dry-run"
        ;;

    *)
        echo "❌ Wrong command"
        exit 1
        ;;

    esac

    cd $DIR_CH
    
    touch overrides.yaml
    [[ "$FLAGS" ]] && FLAGS+=" -f $(pwd)/overrides.yaml"
    
    # FOR EVERY HELM RELEASE ###########################################################
    # ℹ️ Notice: in chart folder you should have subfolder with name in format: 
    #      [0-9][0-9]_release_<release-name>
    # where:
    #  - digits define the instalation order 
    #  - release-name is name of release to be installed
    # The release-name will be used in command:
    #     helm install release-name helm-repo/chart-name
    #
    # If you want to run some preparing script (for ex: init database, check conditions) 
    # before installing, place your code in pre-relese-script.sh in release subfolder
    #
    # If you want to run some post-installing script (for ex: validate something),
    # place you code in post-relese-script.sh in release subfolder
    # ##################################################################################
    for DIR_RL in [0-9][0-9]_release_*$RL_NAME*/; do

        RELEASE=$([[ -d "$DIR_RL" ]] && echo $DIR_RL | sed 's/[0-9][0-9]_release_//' | sed 's/\///')

        cd $DIR_RL
        # Run pre-release-script if exists
        [[ "$COMMAND" == "install" ]] && [[ -f "pre-release-script.sh" ]] \
            && source pre-release-script.sh
        cd ..

        # evaluate ENV variables
        envsubst < $DIR_RL/override_values.yaml > overrides.yaml


        echo "helm $CMD $RELEASE $FLAGS"
        [[ "$CMD" ]] && [[ "$CHART" ]] && [[ "$RELEASE" ]] && \
                    helm $CMD $RELEASE $FLAGS

        cd $DIR_RL
        # Run post-release-script if exists
        [[ "$COMMAND" == "install" ]] && [[ -f "post-release-script.sh" ]] \
            && source post-release-script.sh
        cd ..
    
    done

    cd ..

done
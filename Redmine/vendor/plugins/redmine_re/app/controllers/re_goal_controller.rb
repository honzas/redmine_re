class ReGoalController < RedmineReController
  unloadable

  def index
    @goals = ReGoal.find(:all,
                         :joins => :re_artifact,
                         :conditions => {:re_artifacts => {:project_id => @project.id}}
    )
    render :layout => false if params[:layout] == 'false'
  end

  ##
  # redirects to edit to be more dry
  def new
    edit
  end

  ##
  # edit can be used for new/edit and update
  def edit
      #if request.get?
        # Parameter id contains id of ReArtifact, not of ReSubtask as it should be
        # This has to be changed here as it is not possible to build
        # a dynamic Ajax-Updater with data from clicked tree-element
        re_artifact_id = params[:id]
        @re_artifact = ReArtifact.find_by_id(re_artifact_id)
        params[:id] = @re_artifact.artifact_id
      #end
      @re_goal = ReGoal.find_by_id(params[:id], :include => :re_artifact) || ReGoal.new
      @re_goal.build_re_artifact unless @re_goal.re_artifact
      # If no parent_id is transmitted, we don't create a new artifact but edit one
      # Therefore, a valid parent_artifact_id is existent and has to be read out
      if request.get?
        if params[:parent_id] == nil
          params[:parent_id] = @re_goal.re_artifact.parent_artifact_id
        end
      end
      if request.post?
        # Params Hash anpassen
        ## 1. Den Key re_artifact in re_artifact_attributes kopieren und l�schen
        ### Params Hash aktuell BSP: "re_task"=>{"re_artifact"=>{"name"=>"TaskArtifactEditTesterV3", "priority"=>"777777"}
        params[:re_goal][:re_artifact_attributes] = params[:re_goal].delete(:re_artifact)

        ### Params Hash aktuell BSP:"re_task"=>{"re_artifact_attributes"=>{"name"=>"TaskArtifactEditTesterV3", "priority"=>"777777"}

        ## 2. Den Key re_artifact_attributes die id hinzuf�gen, weil sonst bei Edit neues ReArtifact erzeugt wird da keine Id gefunden wird
        params[:re_goal][:re_artifact_attributes][:id] = @re_goal.re_artifact.id

        ### Params Hash aktuell BSP:"re_task"=>{"re_artifact_attributes"=>{ "id"=>37,"name"=>"TaskArtifactEditTesterV3", "priority"=>"777777"}

        # dies funktioniert nun (nur mit re_artifact_attributes key halt)
        @re_goal.attributes = params[:re_goal]
        add_hidden_re_artifact_attributes @re_goal.re_artifact
        @re_goal.re_artifact.parent_artifact_id = params[:parent_id] if params[:parent_id] and @re_goal.new_record?
        # Todo: Abkl�ren, wo ReArtifact gespeichert wird. Geht das �ber re_task.save automatisch?
        flash[:notice] = 'Goal successfully saved' unless save_ok = @re_goal.save
        # we won't put errors in the flash, since they can be displayed in the errors object

        redirect_to :action => 'index', :project_id => @project.id, :layout => 'false' and return if save_ok
      end
  end

  ##
  # deletes and updates the flash with either success, id not found error or deletion error
  def delete
    @re_goal = ReGoal.find_by_id(params[:id], :include => :re_artifact)
    if !@re_goal
      flash[:error] = 'Could not find a goal with this ' + params[:id] + ' to delete'
    else
      # might be replaced by :dependend => :nullify in artifact model
      children = []
      children << @re_goal.re_artifact.children
      name = @re_goal.re_artifact.name
      for child in children do
          child.parent_artifact_id = nil
          child.save
      end
      if ReGoal.delete(@re_goal.id)
        flash[:notice] = 'The Goal "' + name + '" has been deleted'
      else
        flash[:error] = 'The Goal "' + name + '" could not be deleted'
      end
    end
    redirect_to :action => 'index', :project_id => @project.id
  end

  ##
  # unused right now
  def show
    @re_goal= ReGoal.find_by_id(params[:id])
  end

end
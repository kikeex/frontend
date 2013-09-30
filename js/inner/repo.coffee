 ## A Repo comes from github, may or may not be in the DB yet
CI.inner.Repo = class Repo extends CI.inner.Obj
  observables: =>
    following: false

  constructor: (json) ->
    super json
    CI.inner.VcsUrlMixin(@)

    @canFollow = @komp =>
      not @following() and @has_followers

    @shouldDoFirstFollowerBuild = @komp =>
      not @following() and @admin and not @has_followers

    @requiresInvite = @komp =>
      not @following() and not @admin and not @has_followers

    @displayName = @komp =>
      if @fork
        @project_name()
      else
        @name



  unfollow: (data, event) =>
    $.ajax
      type: "POST"
      event: event
      url: "/api/v1/project/#{@project_name()}/unfollow"
      success: (data) =>
        @following(false)
        _gaq.push(['_trackEvent', 'Repos', 'Remove']);

  follow: (data, event) =>
    $.ajax
      type: "POST"
      event: event
      url: "/api/v1/project/#{@project_name()}/follow"
      success: (successData) =>
        _gaq.push(['_trackEvent', 'Repos', 'Add']);
        if successData.first_build
          VM.visit_local_url data.first_build.build_url
        else if @shouldDoFirstFollowerBuild()
          @doFirstFollowerBuild(data, event)
        else
          $('html, body').animate({ scrollTop: 0 }, 0);
          VM.loadRecentBuilds()
        @following(true)

  doFirstFollowerBuild: (data, event) =>
    $.ajax
      type: "POST"
      event: event
      url: "/api/v1/project/#{@project_name()}"
      success: (data) =>
        VM.visit_local_url data.build_url
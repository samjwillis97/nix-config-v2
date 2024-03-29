terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.8.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

locals {
  username = data.coder_workspace.me.owner
}

data "coder_provisioner" "me" {
}

data "coder_parameter" "repository" {
  name        = "Repository"
  description = "Which repository would you like to clone?"
  type        = "string"
  default     = ""

  option {
    name = "AWARE Frontend"
    value = "git@bitbucket.org:ampcontrol/aware-web.git"
    icon = ""
  }

  option {
    name = "AWARE Backend"
    value = "git@bitbucket.org:ampcontrol/aware-api.git"
    icon = ""
  }

  option {
    name = "GGL Frontend"
    value = "git@bitbucket.org:ampcontrol/ggl-web.git"
    icon = ""
  }

  option {
    name = "GGL Backend"
    value = "git@bitbucket.org:ampcontrol/ggl-server.git"
    icon = ""
  }

  option {
    name = "pyAWARE"
    value = "git@bitbucket.org:ampcontrol/pyaware.git"
    icon = ""
  }
}

provider "docker" {
}

data "coder_workspace" "me" {
}

resource "coder_agent" "main" {
  arch                   = data.coder_provisioner.me.arch
  os                     = "linux"
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e
    echo "Starting Code Server Agent in background..."
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    if [ -f /home/${local.username}/.coder_init_done ]; then
      echo "Init script has been run before, exiting."
      exit 0
    fi

    echo "Changing default shell to zsh..."
    sudo usermod --shell /usr/bin/zsh ${local.username}

    echo "Cloning Repository..."
    repository_name=$(echo "${data.coder_parameter.repository.value}" | sed 's/.*\/\([^\/]*\)\.git/\1/')
    git clone ${data.coder_parameter.repository.value} $repository_name 2>&1

    echo "Adding to .zshrc..."
    echo "if [ -d /home/${local.username}/$repository_name ]; then cd /home/${local.username}/$repository_name; fi" >> /home/${local.username}/.zshrc

    if [ -f /home/${local.username}/$repository_name/.envrc ]; then
      echo "Enabling direnv in repo..."
      /home/${local.username}/.nix-profile/bin/direnv allow /home/${local.username}/$repository_name/.envrc
    fi

    if [ -f /home/${local.username}/$repository_name/devenv.nix ]; then
      echo "Fetching dependencies (could take a few minutes)..."
      cd /home/${local.username}/$repository_name
      /home/${local.username}/.nix-profile/bin/devenv ci >/dev/null 2>&1
    fi

    echo "Setting init script as complete... exiting."
    touch /home/${local.username}/.coder_init_done
  EOT

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  # You can remove this block if you'd prefer to configure Git manually or using
  # dotfiles. (see docs/dotfiles.md)
  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/${local.username}"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_volume" "nix_volume" {
  name = "coder-${data.coder_workspace.me.id}-nix"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.me.id}"
  build {
    context = "./build"
    build_args = {
      USER = local.username
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${local.username}"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/nix/"
    volume_name    = docker_volume.nix_volume.name
    read_only      = false
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

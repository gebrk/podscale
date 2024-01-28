# Podscale - simple container to add a Podman pod to Tailscale

**Note:** there is an [official Tailscale docker image](https://tailscale.com/kb/1282/docker) available.
Since this uses binaries downloaded directly from Tailscale rather than building the opensource client directly I do not think these images should be pushed to a public registry without explicit permission from Tailscale.

This containerfile builds an image which only contains the static binaries for the latest stable release of [Tailscale](https://tailscale.com/) and a CA-certs bundle needed for generating ACME certs for [`tailscale serve`](https://tailscale.com/kb/1312/serve). Tailscale ssh is not supported as there is no enviroment to access within the container.

This is intended as a simple way to add a Podman pod to a tailnet either for debugging or for to use `tailscale serve` as a reverse proxy for a webapp in the pod. Beware that the all the services which listen within the pod will be accessible over Tailscale even if not published by Podman - this means it is **highly** recommended to use ACL tags to restrict access to the pod.

Mount a volume at `/state` to keep Tailscale state between runs and consider disabling key expiration in Tailscale for this node. Logs will end up here too.

By default the pod name will be the hostname for the pod on the Tailnet.

## Usage

Build the container locally:
```
cd podscale
podman build -t podscale .
cd -
```

Start a pod containing your application:

```
podman pod create --name podscalepod --replace
podman run --pod=podscalepod docker.io/nginx
```

Add the Podscale container:

```
podman run --pod=podscalepod -it -volume podstate:/state/ -name podscale localhost/podscale
```

Use `podman exec` to use the tailscale client in the container to authenticate (or you could use [auth keys](https://tailscale.com/kb/1085/auth-keys)) and enable `serve` if wanted.

```
podman exec -it podscale /tailscale login
podman exec -it podscale /tailscale serve --bg 80
```

Don't forget to set ACL tags and disable key expiration for long-running pods.

## Hosting static content

You can also use podscale to host static content at a different hostname than the container host os and without exposing its services to the tailnet.

Put your static content in a directory:

```
mkdir content
echo "<h1>Hello Tailnet</h1>" > content/index.html
```

Run the podscale container standalone, not in a pod this time:

```
podman run -it -volume podstate:/state/ -volume $(pwd)/content:/content/ -name podscale localhost/podscale
```

If reusing the state volume from the previous example reset the serve proxy or with a fresh state volume, login.

```
podman exec -it podscale /tailscale serve reset
OR
podman exec -it podscale /tailscale login
```

Set the hostname as this container is not running in a pod:

```
podman exec -it podscale /tailscale set --hostname podscale
```

And serve the content on HTTPS (optionaly on HTTP which will be encrypted over Tailscale):

```
podman exec -it podscale /tailscale serve --bg /content/
podman exec -it podscale /tailscale serve --bg --http=80 /content/
```

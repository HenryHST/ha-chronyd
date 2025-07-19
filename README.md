## About this container

This container runs [chrony](https://chrony-project.org/) on [Alpine Linux](https://alpinelinux.org/).

[chrony](https://chrony-project.org/) is a versatile implementation of the Network Time Protocol (NTP). It can synchronise the system clock with NTP servers, reference clocks (e.g. GPS receiver), and manual input using wristwatch and keyboard. It can also operate as an NTPv4 (RFC 5905) server and peer to provide a time service to other computers in the network.

## Supported Architectures

Architectures officially supported by this Docker container.

## How to Run this container

### With the Docker CLI

Pull and run -- it's this simple.

```
# pull from docker hub
$> docker pull henryhst/ha-chronyd

# run ntp
$> docker run --name=ntp            \
              --restart=always      \
              --detach              \
              --publish=123:123/udp \
              henryhst/ha-chronyd

# OR run ntp with higher security
$> docker run --name=ntp                                           \
              --restart=always                                     \
              --detach                                             \
              --publish=123:123/udp                                \
              --read-only                                          \
              --tmpfs=/etc/chrony:rw,mode=1750,uid=100,gid=101     \
              --tmpfs=/run/chrony:rw,mode=1750,uid=100,gid=101     \
              --tmpfs=/var/lib/chrony:rw,mode=1750,uid=100,gid=101 \
              henryhst/ha-chronyd
```


### With Docker Compose

Using the docker-compose.yml file included in this Git repository, you can build the container yourself (should you choose to).


```
# run ntp
$> docker compose up -d ntp

# (optional) check the ntp logs
$> docker compose logs ntp
```


### With Docker Swarm

*(These instructions assume you already have a swarm)*

```
# deploy ntp stack to the swarm
$> docker stack deploy -c docker-compose.yml chronyd

# check that service is running
$> docker stack services chronyd

# (optional) view the ntp logs
$> docker service logs -f chronyd-ntp
```


### From a Local command line

Using the vars file in this Git repository, you can update any of the variables to reflect your
environment. Once updated, simply execute the build then run scripts.

```
# build ntp
$> ./build.sh

# run ntp
$> ./run.sh
```


## Configure NTP Servers

By default, this container uses the [NTP pool's time servers](https://www.ntppool.org/en/). If you'd
like to use one or more different NTP server(s), you can pass this container an `NTP_SERVERS`
environment variable. This can be done by updating the [vars](vars), [docker-compose.yml](docker-compose.yml)
files or manually passing `--env=NTP_SERVERS="..."` to `docker run`.

Below are some examples of how to configure common NTP Servers.

Do note, to configure more than one server, you must use a comma delimited list WITHOUT spaces.

```
# (default) NTP pool
NTP_SERVERS="0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org"

# cloudflare
NTP_SERVERS="time.cloudflare.com"

# google
NTP_SERVERS="time1.google.com,time2.google.com,time3.google.com,time4.google.com"

# alibaba
NTP_SERVERS="ntp1.aliyun.com,ntp2.aliyun.com,ntp3.aliyun.com,ntp4.aliyun.com"

# local (offline)
NTP_SERVERS="127.127.1.1"
```

If you're interested in a public list of stratum 1 servers, you can have a look at the following lists.

 * https://www.advtimesync.com/docs/manual/stratum1.html (Do make sure to verify the ntp server is active
   as this list does appaer to have some no longer active servers.)
 * https://support.ntp.org/Servers/StratumOneTimeServers

It can also be the case that your use-case does not require a stratum 1 server -- most use-cases don't!

 * https://support.ntp.org/Servers/StratumTwoTimeServers

## Chronyd Options

### No Client Log (noclientlog)

This is optional and not enabled by default. If you provide the `NOCLIENTLOG=true` envivonrment variable,
chrony will be configured to:

> Specifies that client accesses are not to be logged. Normally they are logged, allowing statistics to
> be reported using the clients command in chronyc. This option also effectively disables server support
> for the NTP interleaved mode.


## Logging

By default, this project logs informational messages to stdout, which can be helpful when running the
ntp service. If you'd like to change the level of log verbosity, pass the `LOG_LEVEL` environment
variable to the container, specifying the level (`#`) when you first start it. This option matches
the chrony `-L` option, which support the following levels can to specified: 0 (informational), 1
(warning), 2 (non-fatal error), and 3 (fatal error).

Feel free to check out the project documentation for more information at:

 * https://chrony-project.org/documentation.html


## Setting your timezone

By default the UTC timezone is used, however if you'd like to adjust your NTP server to be running in your
local timezone, all you need to do is provide a `TZ` environment variable following the standard TZ data format.
As an example, using `docker-compose.yaml`, that would look like this if you were located in Vancouver, Canada:

```yaml
  ...
  environment:
    - TZ=America/Vancouver
    ...
```


## Enable Network Time Security

If **all** the `NTP_SERVERS` you have configured support NTS (Network Time Security) you can pass the `ENABLE_NTS=true`
option to the container to enable it. As an example, using `docker-compose.yaml`, that would look like this:

```yaml
  ...
  environment:
    - NTP_SERVERS=time.cloudflare.com
    - ENABLE_NTS=true
    ...
```

If any of the `NTP_SERVERS` you have configured does not support NTS, you will see a message like the
following during startup:

> NTS-KE session with 164.67.62.194:4460 (tick.ucla.edu) timed out


## Enable control of system clock

This option enables the control of the system clock.

By default, chronyd will not try to make any adjustments of the clock. It will assume the clock is free running
and still track its offset and frequency relative to the estimated true time. This allows chronyd to run without
the capability to adjust or set the system clock in order to operate as an NTP server.

Enabling the control requires starting the service as root, granting SYS_TIME capability and a container runtime allowing that access:

```yaml
  ...
  user: "0:0"
  cap_add:
    - SYS_TIME
  environment:
    - ENABLE_SYSCLK=true
    ...
```

## Enable the use of a PTP clock

If you have a `/dev/ptp0`, either a real hardware clock or virtual one provided by a VM host
you can enable the use of it by passing the device to the container. As an example,
using `docker-compose.yaml`, that would look like this:

```yaml
  ...
  devices:
    - /dev/ptp0:/dev/ptp0
```

This will allow chronyd to use the PTP clock as a reference clock. A virtual clock simply provides
the host's system time with great precision and stability; whether that time is accurate depends
on the host provider. In our experience, some VPS vendors give pretty good time (off by
milliseconds), while others are off by seconds.

For information on configuring the host to have a virtual PTP clock, see the following:

 * https://opensource.com/article/17/6/timekeeping-linux-vms


## Testing your NTP Container

From any machine that has `ntpdate` you can query your new NTP container with the follow
command:

```
$> ntpdate -q <DOCKER_HOST_IP>
```


Some code put together to automatically check-in people on [Cobot](https://www.cobot.me/) when connecting to the [Unifi](https://www.ubnt.com/enterprise/#unifi) network.

Still a lot to refactor and extract from `Rakefile`... Sorry for that!

## Available tasks

```bash
$ rake -T
rake cobot:check_in:create[membership_id]         # Check-in a member
rake cobot:check_in:create_for_connected_clients  # 'main' rake task to check-in all connected users
rake cobot:check_in:list                          # List all today's check-ins
rake cobot:invoice:list[membership_id]            # List invoices for a member
rake cobot:members                                # Print a list of all active Cobot members
rake cobot:plan:list                              # List plans for space
rake cobot:time_pass:create[membership_id]        # Create a dont_charge time pass for a member
rake cobot:time_pass:unused[membership_id]        # List unused time passes for a member
rake cobot:token                                  # Generate a new Cobot access token
rake dotenv                                       # Load environment settings from .env
rake redis:ping                                   # PING Redis
rake unifi:clients                                # Print a list of all clients currently connected
rake unifi:devices                                # Print a list of all devices (APs) currently connected
rake unifi:squatters                              # Detect squatters
```

## Cron job

```
0,10,20,30,40,50 9-11,14-16 * * * cd /home/seb/deployment/current && /usr/local/opt/rbenv/shims/bundle exec rake cobot:check_in:create_for_connected_clients >> /var/log/cron.log 2>&1
```

## Environment

You need the following environment variables (in a `.env` file or directly in the environment):

```
UNIFI_USER
UNIFI_PASSWORD
UNIFI_CONTROLLER_ADDRESS
COBOT_ACCESS_TOKEN
SLACK_INCOMING_WEBHOOK_URL
```

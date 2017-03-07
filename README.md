# Bomgar Plugin for MSM

This plugin allows an MSM service desk user to **Create** a Bomgar session from any request. 

Notes are added to the MSM request at the start and end of Bomgar sessions, on session end a link is added in the note for the bomgar report.

## Compatible Versions

| Plugin  | MSM         | JIRA     |
|---------|-------------|----------|
| 1.0.0   | 14.4.0.#### | v7+      |

## Installation

Please see your MSM documentation for information on how to install plugins.

Once the plugin has been installed you will need to configure the following settings within the plugin page:

+ *Bomgar Host* : The URL of your Bomgar instance. `http://[host].bomgar.com/`
+ *Bomgar Port* : The Port for the Bomgar instance. `443`
+ *Bomgar Company* : The company name set up withing bomgar `[company_name]`
+ *Bomgar Username* : The username for authentication with Bomgar.
+ *Bomgar Password* : The password for authentication with Bomgar.
+ *MSM API Key* : The Api key for the user created within MSM to perfom these actions.

## Usage

The plugin can be launched from the quick menu after you load a request.

## Contributing

We welcome all feedback including feature requests and bug reports. Please raise these as issues on GitHub. If you would like to contribute to the project please fork the repository and issue a pull request.
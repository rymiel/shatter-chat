require "json"
require "http/client"
require "compress/zip"

module Shatter::MojangAssets
  module LauncherMeta
    MANIFEST = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json"
    OBJECT = "https://resources.download.minecraft.net/%s/%s"
    alias ManifestVersion = {id: String, type: String, url: String, time: String, releaseTime: String, sha1: String, complianceLevel: Int32}
    alias ManifestSchema = {latest: {release: String, snapshot: String}, versions: Array(ManifestVersion)}
    alias VersionDownload = {sha1: String, size: Int32, url: String}
    alias VersionSchema = {
      assetIndex: {id: String, url: String},
      downloads: Hash(String, VersionDownload)
    }
    alias ObjectSchema = {objects: Hash(String, {hash: String, size: Int32})}
    def self.latest_manifest
      manifest = ManifestSchema.from_json HTTP::Client.get(MANIFEST).body
      latest_id = manifest[:latest][:release]
      manifest[:versions].find(&.[:id].== latest_id).not_nil!
    end

    def self.latest_version
      VersionSchema.from_json HTTP::Client.get(latest_manifest[:url]).body
    end

    def self.latest_assets
      ObjectSchema.from_json HTTP::Client.get(latest_version[:assetIndex][:url]).body
    end

    def self.latest_asset_by_name(name : String)
      hash = latest_assets[:objects][name][:hash]
      HTTP::Client.get(sprintf(OBJECT, hash[...2], hash)).body
    end

    def self.get_language_file(lang_code : String)
      if lang_code == "en_us" # en_us is in the client jar, not in an asset
        client_jar = latest_version[:downloads]["client"]
        HTTP::Client.get(client_jar[:url]) do |r|
          zip_blob = IO::Memory.new client_jar[:size]
          IO.copy r.body_io, zip_blob
          Compress::Zip::File.open(zip_blob) do |zip|
            zip["assets/minecraft/lang/en_us.json"].open do |io|
              Hash(String, String).from_json io.gets_to_end
            end
          end
        end
      else
        Hash(String, String).from_json latest_asset_by_name "minecraft/lang/#{lang_code}.json"
      end
    end
  end
end

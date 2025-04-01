var results = assets
            .GroupBy(a => a.ID) // Partition by ID
            .Select(group =>
            {
                var ordered = group
                    .OrderByDescending(a => a.Listing.LastUpdateDate) // Primary: Listing LastUpdateDate DESC
                    .ThenByDescending(a => a.Vision?.LastUpdateDate ?? DateTime.MinValue) // Secondary: Vision LastUpdateDate DESC
                    .ToList();

                return new
                {
                    Latest = ordered.First(),   // The record to keep
                    Removed = ordered.Skip(1)   // The duplicates (older records)
                };
            })
            .ToList();

        // Extract latest and removed records
        var latestAssets = results.Select(r => r.Latest).ToList();
        var removedAssets = results.SelectMany(r => r.Removed).ToList();
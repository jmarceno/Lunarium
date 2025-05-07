-- Job System
-- Defines character jobs, progressions, and abilities

-- Important:
-- All jobs that have name formed by two or more words, need to have those words Capitalized.
-- Example: "Black Mage" instead of "Blackmage", "White Mage" instead of "Whitemage"

local jobSystem = {
    jobs = {}
}

-- Import job definitions
jobSystem.jobs = require("gameplay/job_definitions")

-- Get a job definition by name
function jobSystem:getJob(name)
    name = name:gsub("%s+", "")
    return self.jobs[name]
end

-- Get all available jobs for a character
function jobSystem:getAvailableJobs(character)
    local available = {}

    -- Ensure character has required fields
    if not character then
        print("Warning: Called getAvailableJobs with nil character")
        return available
    end

    -- Ensure jobLevels exists
    if not character.jobLevels then
        print("Warning: Character " .. character.name .. " missing jobLevels table")
        character.jobLevels = {}
    end

    for name, job in pairs(self.jobs) do
        local canAccess = true
        
        -- Check requirements
        if job.requirements then
            for reqJob, reqLevel in pairs(job.requirements) do
                -- Check jobLevels table instead of jobHistory                
                -- Plase check comment at the top of the file to understand this
                reqJob = reqJob:gsub("(%l)(%u)", "%1 %2")
                -- print("Checking job (on class):", reqJob)
                local jobLevel = character.jobLevels[reqJob] or 0

                if jobLevel < reqLevel then
                    canAccess = false
                    break -- Stop checking requirements for this job
                end
            end
        end

        if canAccess then
            table.insert(available, job)
        end
    end

    -- Sort by tier
    table.sort(available, function(a, b)
        return a.tier < b.tier
    end)

    return available
end

-- Get base jobs (tier 1)
function jobSystem:getBaseJobs()
    local baseJobs = {}

    for name, job in pairs(self.jobs) do
        if job.tier == 1 then
            table.insert(baseJobs, job)
        end
    end

    return baseJobs
end

-- Get job progression options
function jobSystem:getJobProgressions(jobName)
    local progressions = {}
    local currentJob = self:getJob(jobName)

    if not currentJob then
        return {}
    end

    -- Get next tier jobs
    local nextTier = currentJob.tier + 1

    for name, job in pairs(self.jobs) do
        if job.tier == nextTier then
            -- Check if this job requires the current job
            if job.requirements and job.requirements[jobName] then
                table.insert(progressions, job)
            end
        end
    end

    return progressions
end

return jobSystem

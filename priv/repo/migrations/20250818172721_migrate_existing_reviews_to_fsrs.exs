defmodule LeetcodeSpaced.Repo.Migrations.MigrateExistingReviewsToFsrs do
  use Ecto.Migration
  import Ecto.Query

  alias LeetcodeSpaced.Repo
  
  def up do
    # This migration converts existing reviews that might have confidence-based
    # data to the new FSRS system. Since we just implemented FSRS, this is mainly
    # for safety and future-proofing.
    
    # Update any existing reviews that don't have FSRS fields set
    execute """
    UPDATE reviews 
    SET 
      fsrs_state = COALESCE(fsrs_state, 'review'),
      fsrs_step = COALESCE(fsrs_step, 0),
      due = COALESCE(due, next_review, NOW()),
      stability = COALESCE(stability, 2.5),
      difficulty = COALESCE(difficulty, 5.0)
    WHERE fsrs_state IS NULL 
       OR fsrs_step IS NULL 
       OR due IS NULL
    """
    
    # For reviews that had confidence scores, convert them to approximate FSRS difficulty
    execute """
    UPDATE reviews 
    SET difficulty = CASE 
      WHEN confidence <= 2 THEN 8.0  -- Low confidence = high difficulty
      WHEN confidence = 3 THEN 6.0   -- Medium confidence = medium difficulty  
      WHEN confidence = 4 THEN 4.0   -- Good confidence = lower difficulty
      WHEN confidence >= 5 THEN 2.0  -- High confidence = low difficulty
      ELSE 5.0                       -- Default difficulty
    END
    WHERE confidence IS NOT NULL AND difficulty IS NULL
    """
  end

  def down do
    # This migration is largely irreversible since we're converting from
    # a confidence system to FSRS. We can't accurately convert back.
    # The best we can do is clear the FSRS fields.
    
    execute """
    UPDATE reviews 
    SET 
      fsrs_state = NULL,
      fsrs_step = NULL,  
      stability = NULL,
      difficulty = NULL,
      due = NULL,
      last_review = NULL
    """
  end
end

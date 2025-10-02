USE [PEERLESS_ORDER_HISTORY]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[PopulateOrderDelta]
		@SnapshotDate = '2024-10-09',
		@PrevSnapshotDate = '2024-10-08'

SELECT	'Return Value' = @return_value

GO

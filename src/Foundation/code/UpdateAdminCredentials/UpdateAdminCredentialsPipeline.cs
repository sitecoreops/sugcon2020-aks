using Sitecore.Pipelines;
using System.Web.Security;

namespace Foundation.UpdateAdminCredentials
{
    public class UpdateAdminCredentialsPipeline
    {
        private readonly string _sitecoreAdminUsername = "sitecore\\admin";
        public string SitecoreAdminPassword { private get; set; }

        public void Process(PipelineArgs args)
        {
            var user = Membership.GetUser(_sitecoreAdminUsername);

            if (user == null)
            {
                return;
            }

            if (user.IsLockedOut)
            {
                user.UnlockUser();
            }

            user.ChangePassword(user.ResetPassword(), SitecoreAdminPassword);
        }
    }
}
